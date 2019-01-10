import os, sys, re
from Bio import Entrez
from Bio import SeqIO

def choose_best_reference(record):
    if len(record.annotations["references"]):
        # is there a reference which is not a "Direct Submission"?
        titles = [reference.title for reference in record.annotations["references"]]
        try:
            idx = [i for i, j in enumerate(titles) if j is not None and j != "Direct Submission"][0]
        except IndexError: # fall back to direct submission
            idx = [i for i, j in enumerate(titles) if j is not None][0]
        return record.annotations["references"][idx] # <class 'Bio.SeqFeature.Reference'>
    print("\tskipping attribution as no suitable reference found")
    return False


def query_genbank(accessions, email=None, retmax=10, n_entrez=10, gbdb="nuccore", **kwargs):
    store = {}
    # https://www.biostars.org/p/66921/
    if len(accessions) > 10:
        print("Querying genbank accessions {}...".format(accessions[:10]))
    else:
        print("Querying genbank accessions {}".format(accessions))
    if not email:
        email = os.environ['NCBI_EMAIL']
    Entrez.email = email

    # prepare queries for download in chunks no greater than n_entrez
    queries = []
    for i in sorted(range(0, len(accessions), n_entrez)):
        queries.append(set(accessions[i:i+n_entrez]))

    def esearch(accs):
        if len(accs) == 0:
            return
        list_accs = list(accs)
        res = Entrez.read(Entrez.esearch(db=gbdb, term=" ".join(list_accs), retmax=retmax))
        if "ErrorList" in res:
            not_found = res["ErrorList"]["PhraseNotFound"][0]
            accs.remove(not_found)
            esearch(accs)
        else: # success :)
            for i, x in enumerate(list_accs):
                acc_gi_map[x] = res["IdList"][i]

    # populate Accession -> GI number via entrez esearch
    acc_gi_map = {x:None for x in accessions}
    for qq in queries:
        esearch(qq)
    gi_numbers = [x for x in acc_gi_map.values() if x != None]
    gi_acc_map = {v:k for k, v in acc_gi_map.items()}

    # get entrez data vie efetch
    try:
        search_handle = Entrez.epost(db=gbdb, id=",".join(gi_numbers))
        search_results = Entrez.read(search_handle)
        webenv, query_key = search_results["WebEnv"], search_results["QueryKey"]
    except:
        print("ERROR: Couldn't connect with entrez, please run again")
        sys.exit(2)
    for start in range(0, len(gi_numbers), retmax):
        #fetch entries in batch
        try:
            handle = Entrez.efetch(db=gbdb, rettype="gb", retstart=start, retmax=retmax, webenv=webenv, query_key=query_key)
        except IOError:
            print("ERROR: Couldn't connect with entrez, please run again")
        else:
            SeqIO_records = SeqIO.parse(handle, "genbank")
            gi_numbers_pos = start
            for record in SeqIO_records:
                accession_wanted = gi_acc_map[gi_numbers[gi_numbers_pos]]
                accession_received = re.match(r'^([^.]*)', record.id).group(0).upper()
                gi_numbers_pos += 1
                if accession_received != accession_wanted:
                    print("Accession mismatch. Skipping.")
                else:
                    store[accession_wanted] = record
    return store


def fix_date(date_in):
  match = re.match(r"([0-9]{4})[/-]([0-9X]{2})[/-]([0-9X]{2})", date_in)
  if match:
    return "{}-{}-{}".format(match.group(1), match.group(2), match.group(3))
  match = re.match(r"([0-9]{4})[/-]([0-9X]{2})$", date_in)
  if match:
    return "{}-{}-XX".format(match.group(1), match.group(2))
  match = re.match(r"\d{4}$", date_in)
  if match:
    return "{}-XX-XX".format(match[0])
  match = re.match(r"(\d+)[/-](\d+)[/-](\d+)$", date_in)
  if match:
      # because of the CSV format, we _assume_ this is month/day/year
    if int(match.group(1)) > 12:
      print("BAD DATE FORMAT: {}".format(date_in))
      sys.exit(2)
    year = match.group(3) # string
    if len(year) == 2:
      if int(year) > 20:
        year = "19{}".format(year)
      else:
        year = "20{}".format(year)
    return "{:0>2}-{:0>2}-{:0>2}".format(year, match.group(1), match.group(2))
  print("UNKNOWN DATE {}".format(date_in))
  sys.exit(2)


def parseFasta(path, sep="_", unknown="Unknown"):
    seqs = {}
    metadata = {}
    with open(path, "rU") as f:
        for record in SeqIO.parse(f, "fasta"):
            header = re.split('[|_]+', record.description) # fasta delimiters used include "_" and "|"
            strain = header[0].split(".")[0] # MF175814.1 -> MF175814 as this is what the CSV uses
            seqs[strain] = record.seq
            metadata[strain] = {
                'strain': strain,
                'date': unknown,
                'country': unknown,
                'state': unknown,
                'division': unknown,
                'host': unknown,
                'lineage': unknown,
                'authors': unknown,
                'journal': unknown,
                'title': unknown,
                'url': unknown,
                'latitude': unknown,
                'longitude': unknown
            }
            try:
              date = fix_date(header[1])
              metadata[strain]['date'] = date
              metadata[strain]['country']   = header[2] if header[2] else unknown
              metadata[strain]['state']     = header[3] if header[3] else unknown
              metadata[strain]['division']  = header[4] if header[4] else unknown
              metadata[strain]['longitude'] = header[5] if header[5] else unknown
              metadata[strain]['latitude']  = header[6] if header[6] else unknown
            except IndexError:
              pass
              # print("WARNING: {} incomplete FASTA header".format(strain))
    return (seqs, metadata)

def addMetadataFromInputCSV(metadata, path, unknown="Unknown"):
    print("parsing hosts & lineage from ", path)
    hosts = {} # strain -> host map
    lineage = {} # strain -> lineage map
    with open(path, "rU") as f:
        for line in f:
            fields = line.strip().split(',')
            try:
                assert(len(fields) >= 7)
            except AssertionError:
                print("Not enough many fields in metadata. Line:")
                print(line)
                sys.exit(2)
            strain = fields[0] # note that strain == accession

            if strain not in metadata:
              print("WARNING: Strain {} in CSV not found in FASTA".format(strain))
              continue
            
            # DATE
            csv_date = fix_date(fields[1])
            if metadata[strain]["date"] == unknown:
              metadata[strain]["date"] = csv_date
            else:
              if metadata[strain]["date"] != csv_date:
                if metadata[strain]["date"].split("-")[0] != csv_date.split("-")[0]:
                  print("ERROR: Mismatch in dates! Check the FASTA & CSV for {}".format(strain))
                  sys.exit(2)
                a, b = [metadata[strain]["date"].count("X"), csv_date.count("X")]
                if a > b:
                  # print("Changing {} date from {} (FASTA) to {} (CSV)".format(strain, metadata[strain]["date"], csv_date))
                  metadata[strain]["date"] = csv_date

            # the other fields are simpler
            pairs = (
              ("country", 2),
              ("state", 3),
              ("division", 4),
              ("host", 5),
              ("lineage", 6)
            )
            for pair in pairs:
              name, idx = pair
              if fields[idx]:
                if metadata[strain][name] == unknown:
                  metadata[strain][name] = fields[idx]
                elif metadata[strain][name] != fields[idx]:
                  print("CHECK: {} {} mismatch: {} - {}".format(strain, name, metadata[strain][name], fields[idx]))

def addHardcodedAuthorInfo(metadata):
    for accession, data in metadata.items():
        if re.match(r'^W\d+$', accession):
            data["authors"] = "Grubaugh et al"
            data["journal"] = "Unpublished"
            data["title"] = "West Nile virus genomic data from California"
            data["url"] = "https://andersen-lab.com/secrets/data/west-nile-genomics/"


def addAuthorInfoViaEntrez(metadata):
    accessions = [acc for acc, data in metadata.items() if data["authors"] == "Unknown"]
    gb = query_genbank([x for x in accessions if len(x) > 5]) # don't query obviously non-accession strings
    refs = {accession: choose_best_reference(record) for accession, record in gb.items()}
    for accession, entrezData in refs.items():
        metadata[accession]["authors"] = re.match(r'^([^,]*)', entrezData.authors).group(0) + " et al"
        metadata[accession]["journal"] = entrezData.journal
        metadata[accession]["title"] = entrezData.title
        if not entrezData.pubmed_id:
            # print("no pubmed_id for ", metadata[accession]["authors"], metadata[accession]["title"], ". Falling back to nuccore/accession")
            metadata[accession]["url"] = "https://www.ncbi.nlm.nih.gov/nuccore/" + accession
        else:
            metadata[accession]["url"] = "https://www.ncbi.nlm.nih.gov/pubmed/" + entrezData.pubmed_id


def filterByGenomeLength(seqs, metadata, minLength):
    strains = list(seqs.keys())
    count = 0
    for strain in strains:
        seq_len = len(re.findall('[atcg]', str(seqs[strain]), re.IGNORECASE))
        if seq_len < minLength:
            del metadata[strain]
            del seqs[strain]
            count += 1
    print("removed {} sequences which were less than {}bp".format(count, minLength))


def writeFasta(seqs, path):
    with open(path, 'w') as fh:
        for strain, seq in seqs.items():
            fh.write(">{}\n{}\n".format(strain, str(seq)))

def writeMetadataTSV(metadata, path):
    header = metadata[list(metadata.keys())[0]].keys()
    with open(path, 'w') as fh:
        print("\t".join(header), file=fh)
        for strain, data in metadata.items():
            print("\t".join([data[k] for k in header]), file=fh)

def add_state_to_division(metadata):
  for _, x in metadata.items():
    d, s = [x["division"], x["state"]]
    if d != "Unknown" and s != "Unknown":
      x["division"] = "{}/{}".format(s, d)
    elif d == "Unknown":
      x["division"] = s

if __name__ == "__main__":
    fasta_in, meta_in, fasta_out, meta_out = sys.argv[1:]
    print("Custom WNV parser which converts {} & {} -> {} & {}".format(fasta_in, meta_in, fasta_out, meta_out))
    print("Expected metadata fields (CSV): [0]accession, [1]date, [2]country, [3]state, [4]location, [5]host, [6]lineage")
    print("Expected FASTA format: <accession>_<YYYY-MM-DD>_<country>_<state>_<loc>_<long>_<lat>")
    print("")
    print("Step1: collects fasta and CSV metadata")
    print("Step2: cleans up FASTA header")
    print("Step3: queries ENTREZ for author information (not included in input files)")
    print("Step4: subsamples out sequences less than 10kb")
    print("Step5: adds state to division label to avoid ambiguity")
    print("\n")

    seqs, metadata = parseFasta(fasta_in)
    addMetadataFromInputCSV(metadata, meta_in)
    addHardcodedAuthorInfo(metadata)
    addAuthorInfoViaEntrez(metadata)
    filterByGenomeLength(seqs, metadata, 10000)
    add_state_to_division(metadata)

    try:
        os.mkdir("results")
    except OSError:
        pass
    writeFasta(seqs, fasta_out)
    writeMetadataTSV(metadata, meta_out)
