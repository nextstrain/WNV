import os, sys, re
from Bio import SeqIO

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
              # most information will be extracted from the CSV file
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
    print("Step3: subsamples out sequences less than 7kb")
    print("Step4: adds state to division label to avoid ambiguity")
    print("\n")

    seqs, metadata = parseFasta(fasta_in)
    addMetadataFromInputCSV(metadata, meta_in)
    filterByGenomeLength(seqs, metadata, 7000)
    add_state_to_division(metadata)

    try:
        os.mkdir("results")
    except OSError:
        pass
    writeFasta(seqs, fasta_out)
    writeMetadataTSV(metadata, meta_out)
