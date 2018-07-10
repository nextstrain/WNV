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

def parseFasta(path, sep="_", unknown="Unknown"):
    seqs = {}
    metadata = {}
    with open(path, "rU") as f:
        for record in SeqIO.parse(f, "fasta"):
            header = record.description.split(sep)
            strain = header[0]
            try:
                assert(len(header) == 7)
            except AssertionError:
                print("Incorrect number of fields in this FASTA header", record.description)
                sys.exit(2)
            metadata[strain] = {
                'strain': header[0],
                'date': header[1],
                'country': header[2],
                'state': header[3],
                'division': header[4],
                'host': unknown,
                'lineage': unknown,
                'authors': "",
                'journal': "",
                'title': "",
                'url': ""
            }
            seqs[strain] = record.seq
    return (seqs, metadata)

def addMetadataFromInputCSV(metadata, path):
    print("parsing hosts & lineage from ", path)
    hosts = {} # strain -> host map
    lineage = {} # strain -> lineage map
    with open(path, "rU") as f:
        for line in f:
            fields = line.strip().split(',')
            try:
                assert(len(fields) == 7)
            except AssertionError:
                print("Too many fields in metadata. Line:")
                print(line)
                sys.exit(2)
            strain = fields[0] # note that strain == accession
            try:
                metadata[strain]["host"] = fields[5]
                metadata[strain]["lineage"] = fields[6]
            except KeyError:
                print("Strain {} in CSV not found in FASTA".format(strain))
                sys.exit(2)

def addHardcodedAuthoInfo(metadata):
    for accession, data in metadata.items():
        if re.match(r'^W\d+$', accession):
            data["authors"] = "Grubaugh et al"
            data["journal"] = "Unpublished"
            data["title"] = "West Nile virus genomic data from California"
            data["url"] = "https://andersen-lab.com/secrets/data/west-nile-genomics/"


def addAuthorInfoViaEntrez(metadata):
    accessions = [acc for acc, data in metadata.items() if data["authors"] == ""]
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

def filterByAuthor(seqs, metadata, authorToExclude):
    strains = list(seqs.keys())
    count = 0
    for strain in strains:
        if metadata[strain]["authors"] == authorToExclude:
            del metadata[strain]
            del seqs[strain]
            count += 1
    print("removed {} sequences from {}".format(count, authorToExclude))

def filterByGenomeLength(seqs, metadata, minLength):
    strains = list(seqs.keys())
    count = 0
    for strain in strains:
        if len(seqs[strain]) < minLength:
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

if __name__ == "__main__":
    fasta_in, meta_in, fasta_out, meta_out = sys.argv[1:]
    print("Custom WNV parser which converts {} & {} -> {} & {}".format(fasta_in, meta_in, fasta_out, meta_out))
    print("queries ENTREZ for author information as this isn't included in {}".format(meta_in))
    print("also filters out sequences less than 10kb or those from Shabman et al.\n\n\n")

    seqs, metadata = parseFasta(fasta_in)
    addMetadataFromInputCSV(metadata, meta_in)
    addHardcodedAuthoInfo(metadata)
    addAuthorInfoViaEntrez(metadata)
    filterByAuthor(seqs, metadata, "Shabman et al")
    filterByGenomeLength(seqs, metadata, 10000)
    try:
        os.mkdir("results")
    except OSError:
        pass
    writeFasta(seqs, fasta_out)
    writeMetadataTSV(metadata, meta_out)
