import os, sys, re
from Bio import Entrez
from Bio import SeqIO
from datetime import datetime
import time

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


def query_genbank(accessions, email=None, retmax=10, n_entrez=10, gbdb="nuccore"):
    store = {}
    # https://www.biostars.org/p/66921/
    print("Querying {} genbank accessions {}...".format(len(accessions), accessions[:3]))
    email = os.environ['NCBI_EMAIL']
    if not email:
      print("You must set an email for NCBI accessible at the ${NCBI_EMAIL} bash env variable")
      sys.exit(2)
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
            for i, accession in enumerate(list_accs):
                gi_num = res["IdList"][i]
                maps["accession_gi"][accession] = gi_num
                maps["gi_accession"][gi_num] = accession

    maps = {
      "accession_gi": {},
      "gi_accession": {}
    }
    print("Linking Accessions to GI numbers...")
    for idx, query_chunk in enumerate(queries):
        print("\r\tprogress: {}/{}        ".format(idx+1, len(queries)), end="")
        esearch(query_chunk)
    print("")


    print("Getting ENTREZ records for GI numbers...")
    for idx, query_chunk in enumerate(queries):
      gi_numbers = [maps["accession_gi"][acc] for acc in query_chunk]
      print("\r\tprogress: {}/{} (n={})       ".format(idx+1, len(queries), len(query_chunk)), end="")

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
                  accession_wanted = maps["gi_accession"][gi_numbers[gi_numbers_pos]]
                  accession_received = re.match(r'^([^.]*)', record.id).group(0).upper()
                  gi_numbers_pos += 1
                  if accession_received != accession_wanted:
                      print("Accession mismatch. Skipping.")
                  else:
                      store[accession_wanted] = record
    print("")
    return store




def add_hardcoded_authors(metadata, missing):
  for accession, data in metadata.items():
    if re.match(r'^W\d+$', accession):
      missing.remove(accession)
      data["authors"] = "WestNile4K"
      data["journal"] = "Unpublished"
      data["title"] = "WestNile 4K Project"
      data["url"] = "https://westnile4k.org/"


def add_authors_using_entrez(metadata, cache, missing):
    accessions = [x for x in list(missing) if len(x) > 5] # prune short strings which are obviously non-accession strings
    gb = query_genbank(accessions)
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
        cache[accession] = {}
        for key in ["authors", "journal", "title", "url"]:
          cache[accession][key] = metadata[accession][key]


def writeMetadataTSV(metadata, path):
    header = metadata[list(metadata.keys())[0]].keys()
    with open(path, 'w') as fh:
        print("\t".join(header), file=fh)
        for strain, data in metadata.items():
            print("\t".join([data[k] for k in header]), file=fh)

def parse_TSV(path):
  with open(path, 'r') as fh:
    header = fh.readline().strip().split("\t")
    meta = {}
    for line in fh:
      fields = line.strip().split("\t")
      try:
        assert(len(fields) == len(header))
      except AssertionError:
        print("Not enough many fields in metadata. Line:")
        print(line)
        sys.exit(2)
      meta[fields[0]] = {k:v for k, v in zip(header, fields)}
  return (header, meta, set(meta.keys()))

def read_cache(path):
    cache = {}
    try:
      with open(path, "r") as f:
        for line in f:
          fields = line.strip().split("\t")
          cache[fields[0]] = {
            "authors": fields[1],
            "journal": fields[2],
            "title": fields[3],
            "url": fields[4]
          }
    except OSError:
      print("No cache (yet)")
    return cache

def write_cache(cache, path):
  print("Writing cache out to {}".format(path))
  with open(path, "w") as f:
    for acc, data in cache.items():
      f.write("{}\t{}\t{}\t{}\t{}\n".format(acc, data["authors"], data["journal"], data["title"], data["url"]))

def write_metadata(meta, header, path):
  print("Writing metadata out to {}".format(path))
  with open(path, "w") as f:
    f.write("{}\n".format("\t".join(header)))
    for _, values in meta.items():
      f.write("{}\n".format("\t".join([values[key] for key in header])))


def fill_in_using_cache(meta, cache, missing):
  count = 0
  for acc, data in cache.items():
    if acc in meta:
      missing.remove(acc)
      count += 1
      for key, value in data.items():
        meta[acc][key] = value
  print("Cache used for {} strains".format(count))

previous = 1
if __name__ == "__main__":
    meta_in,  meta_out = sys.argv[1:]
    cache_path = "results/author_cache.tsv"
    print("Custom WNV script to add authors to metadata TSV via ENTREZ query")
    print("Input : {}, Cache: {}, Output: {}".format(meta_in, cache_path, meta_out))
    
    header, meta, missing = parse_TSV(meta_in)
    cache = read_cache(cache_path)
    fill_in_using_cache(meta, cache, missing)
    add_hardcoded_authors(meta, missing)
    
    current = time.time()
    delay = 0.4
    elapsed = current - previous
    wait = delay - elapsed
    
    add_authors_using_entrez(meta, cache, missing)
    write_cache(cache, cache_path)
    write_metadata(meta, header, meta_out)
