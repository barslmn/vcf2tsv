#!/usr/bin/awk -f

BEGIN {
	FS = "\t"
	infoheader = ""
	formatheader = ""
}

/^##FORMAT/ {
	gsub("##FORMAT=<ID=", "", $0)
	gsub(",.*$", "", $0)
	if (formatheader == ""){
		formatheader = $0
	} else {
		formatheader = formatheader"\t"$0
	}
	next
}

/^##INFO=<ID=CSQ/ {
	csq=1
	info = $0
	# gsub("##INFO=<ID=", "", $0)
	# gsub(",.*$", "", $0)
	# if (infoheader == ""){
	# 	infoheader = $0
	# } else {
	# 	infoheader = infoheader"\t"$0
	# }
	gsub("^.*Format: ", "", info)
	gsub("\">$", "", info)
	veparraylength = split(info, veparray, "|")
	next
}

/^##INFO/ {
	gsub("##INFO=<ID=", "", $0)
	gsub(",.*$", "", $0)
	if (infoheader == ""){
		infoheader = $0
	} else {
		infoheader = infoheader"\t"$0
	}
	next
}

/^##/ { next }
/^#CHROM/ {
	split($0, header, "\t")
	infoheaderlength=split(infoheader, infoheaderarray, "\t")
	formatheaderlength=split(formatheader, formatheaderarray, "\t")
	vepheader = join(veparray, veparraylength, "\t")

	# Get index of CSQ
	if (csq) {
		for (j = 1; j <= infoheaderlength; ++j) {
			if (infoheaderarray[j] == "CSQ") {
				csqindex = j;
			}
		}
	}

	print header[1]"\t"header[2]"\t"header[3]"\t"header[4]"\t"header[5]"\t"header[6]"\t"header[7]"\t"infoheader"\t"vepheader"\t"formatheader
	next
}

function dot(el) {
	if (length(el) == 0) {
		return "."
	} else {
		return el
	}
}

function join(array, end, sep) {
	result = ""
	for (joinindex = 1; joinindex <= end; joinindex++)
		if (joinindex == 1) {
			result = dot(array[joinindex])
		} else {
			result = result sep dot(array[joinindex])
		}
	return result
}

function includes(array, end, value) {
	result = 0
	for (i = 1; i <= end; i++)
		if ( value == array[i]) {
			result = 1
		}
	return result
}

function parsecsq(csqfield, info) {
	csqlength = split(csqfield, csqarray, ",")
	infowithcsq = ""
	for (i = 1; i <= csqlength; ++i) {
		transcriptlength = split(csqarray[i], transcriptarray, "|")
		transcriptcsq = join(transcriptarray, transcriptlength, "\t")

		if (i == 1) {
			infowithcsq = info"\t"transcriptcsq
		} else {
			infowithcsq = infowithcsq";"info"\t"transcriptcsq
		}
	}
	return infowithcsq;
}

function parseinfo(info) {
	infolength = split(info, infoarray, ";")

	info = ""
	for (j = 1; j <= infoheaderlength; ++j) {
		infokeys=""
		for (i = 1; i <= infolength; ++i) {
			split(infoarray[i], infokeyvalue, "=")
			# Add CSQ after all the info fields
			if (csq == 1 && infokeyvalue[1] == "CSQ" && j == infoheaderlength) {
				csqfield = infokeyvalue[2]
			} else {
				infokeys = infokeys infokeyvalue[1]"\t"
				if (infoheaderarray[j] == infokeyvalue[1]) {
					if (i == infoheaderlength) {
						info = info infokeyvalue[2]
					} else if (i < infoheaderlength) {
						info = info infokeyvalue[2]"\t"
					}
				}
			}
		}
		infokeyslength = split(infokeys, infokeyarray, "\t")
		if (!includes(infokeyarray, infokeyslength, infoheaderarray[j])) {
			if (j == infoheaderlength) {
				info = info "."
			} else if (j < infoheaderlength) {
				info = info ".\t"
			}
		}
	}
	if (csq == 1) {
		return parsecsq(csqfield, info);
	} else {
		return info;
	}
}

function parsegenotype(format, genotype) {
	genotypelength = split(genotype, genotypearray, ":")
	# genotype = join(genotypearray, genotypelength, "\t")
	formatlength = split(format, formatarray, ":")
	format = join(formatarray, formatlength, "")
	if (genotypelength != formatlength) {
		printf("Error while parsing line number %s\nThere seems to be a problem with format and genotype columns.", NR)
	}

	genotype = ""
	for (j = 1; j <= formatheaderlength; ++j) {
		for (i = 1; i <= genotypelength; ++i) {
			if (formatheaderarray[j] == formatarray[i])
				genotype = genotype genotypearray[i]"\t"
		}
		if (!includes(formatarray, formatlength, formatheaderarray[j])){
			if (j < formatheaderlength - 1) {
				genotype = genotype ".\t"
			} else if (j == formatheaderlength - 1) {
				genotype = genotype "."
			}
		}
	}
	return genotype;
}

{
	info = parseinfo($8);
	genotype = parsegenotype($9, $10);
	infolength = split(info, infoarray, ";")
	for (i = 1; i <= infolength; ++i) {
		print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"infoarray[i]"\t"genotype
	}
}
