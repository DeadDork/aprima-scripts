#!/bin/bash

##################################################################################################
#    Copyright © 2012 by Nimrod Omer <https://wwww.github.com/DeadDork>.                         #
#                                                                                                #
#    Permission to use, copy, modify, and/or distribute this software for any purpose            #
#    with or without fee is hereby granted, provided that the above copyright notice             #
#    and this permission notice appear in all copies.                                            #
#                                                                                                #
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO     #
#    THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.              #
#    IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL  #
#    DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,              #
#    WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING              #
#    OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.                       #
##################################################################################################

# Aprima's patient notes bulk export function is broken. This script let's a user with access to the DBMS to quickly export patient visit notes.

# Prompt and read user input for a number of variables.
read -p 'Server name to connect to with sqsh (e.g. tnh_mss)? ' server
read -p 'Sqsh user name (e.g. "domain\\nimrod")? ' user
read -p 'Sqsh password (e.g. "yeah right, buddy")? ' password

read -p 'Patient first name? ' px_FirstName
read -p 'Patient last name? ' px_LastName

read -p 'Output folder (e.g. "/home/work_two/work/TrueNorthDecrypt/scripts/aprima-scripts/visit_notes_exporter/rtf_depository")? ' output_folder
output_folder="${output_folder}/${px_FirstName}_${px_LastName}"

read -p 'Doctor first name? ' rx_FirstName
read -p 'Doctor last name? ' rx_LastName

# Determine the patient whose doctor visit notes are desires for export, as well as the doctor who treated the patient.
echo "SQSH:"
sqsh -S "${server}" -U "${user}" -P "${password}" -C "select FirstName, LastName, BirthDate, cast(PersonUid as varchar(max)) as PersonUid from prm.dbo.person where (FirstName = '${px_FirstName}' and LastName = '${px_LastName}') or (FirstName = '${rx_FirstName}' and LastName = '${rx_LastName}')" -m pretty
read -p 'Copy and paste the PersonUid of the patient whose visit notes you want to export. ' PatientUid
read -p 'Copy and paste the PersonUid of the doctor of the patient whose visit notes you want to export. ' DoctorUid

# A csv of each visit note's unique identifier & the date of the note.
echo "SQSH:"
sqsh -S "${server}" -U "${user}" -P "${password}" -C "select cast(VisitUid as varchar(max)), cast(year(VisitDate) as varchar(max)) + '-' + cast(month(VisitDate) as varchar(max)) + '-' + cast(day(VisitDate) as varchar(max)) + '_' + cast(cast(VisitDate as time) as varchar(max)) from prm.dbo.visit where PatientUid = '${PatientUid}' and ProviderUid = '${DoctorUid}'" -L bcp_colsep='|' -L bcp_rowsep='' -m bcp > /tmp/aprima_VisitNotes_export.csv

# Generate sqsh scripts from the above csv that, when executed, will produce the visit notes.
awk 'BEGIN {FS="|"} {print "select\n\t\tCCComment\n\tfrom\n\t\tprm.dbo.VisitComment\n\twhere\n\t\tVisitUid = '\''" $1 "'\''\n\\go -m bcp > '"${output_folder}/${px_FirstName}_${px_LastName}_"'" $2 ".rtf"}' < /tmp/aprima_VisitNotes_export.csv > /tmp/aprima_VisitNotes_export.sqsh

# Makes sure that the output folder exists, and if it doesn't, creates it. The reason I put this command here is that I can imagine making an entry error somewhere above & prematurely exiting this script. Accordingly, it makes more sense to make sure the directory exists right at the last moment.
[ ! -d "${output_folder}" ] && mkdir -p "${output_folder}"

# Execute the sqsh script that will generate the visit notes rtf files.
echo "SQSH:"
sqsh -S "${server}" -U "${user}" -P "${password}" -L bcp_colsep='' -L bcp_rowsep='' -i /tmp/aprima_VisitNotes_export.sqsh

exit 0
