property maxNotesToImport : -1
property showAttachmentError : true
property stackTagPrefix : "stack:"

-- temporary files needed for notes attachment base64 conversion
property tmpNoteContentPath : (((path to desktop folder) as string) & "evernote2AppleNotesContent.tmp")
property tmpAttachmentFilePath : (((path to desktop folder) as string) & "evernote2AppleNotesAttachment.tmp")
property tmpAttachmentB64FilePath : (((path to desktop folder) as string) & "evernote2AppleNotesAttachmentB64.tmp")
-- save current clipboard content to set it back afterwards (image base64)
property clipboardContent : do shell script "pbpaste"

set importRootFolder to null
set importRootFolderName to "_ImportedNotes" & my nowYYYYMMDDMMSS()
set importedNotesCount to 0

tell application "Evernote Legacy" to launch
tell application "Notes" to launch

tell application "Notes"
	log "Create import root folder " & importRootFolderName
	set importRootFolder to make new folder with properties {name:importRootFolderName}
end tell

tell application "Evernote Legacy"
	set allNotes to find notes
	set allNotesCount to count of allNotes
	set allNotebooks to every notebook
	repeat with currentNoteBook in allNotebooks
		set notebookName to (the name of currentNoteBook)
		set notebookNotes to every note in notebook notebookName
		set notebookNotesCount to count of notebookNotes
		set notebookNotesCounter to 1
		repeat with currentNote in notebookNotes
			log "Importing Note " & notebookNotesCounter & "/" & notebookNotesCount & " from Evernote notebook " & notebookName
			set noteTitle to (the title of currentNote)
			set noteContent to HTML content of currentNote
			set noteCreationDate to creation date of currentNote
			set noteModificationDate to modification date of currentNote
			set noteContent to my getNoteContentFromEvernoteNote(currentNote)
			set noteContent to "<div><h1>" & noteTitle & "</h1></div><div><br></div>" & noteContent
			set noteTitle to ""
			
			-- Stack Folder
			set stackFolder to null
			set stackName to my extractStackName(the tags of currentNote)
			if stackName is not null then
				set stackFolder to my getNotesSubFolder(importRootFolder, stackName)
				if stackFolder is null then
					tell application "Notes"
						log "Create stack folder " & stackName
						set stackFolder to make new folder at importRootFolder with properties {name:stackName}
					end tell
				end if
			end if
			set parentImportFolder to null
			if stackFolder is not null then
				set parentImportFolder to stackFolder
			else
				set parentImportFolder to importRootFolder
			end if
			set notebookName to the name of the notebook of currentNote
			set notebookFolder to my getNotesSubFolder(parentImportFolder, notebookName)
			if notebookFolder is null then
				tell application "Notes"
					log "Create notebook folder " & notebookName
					set notebookFolder to make new folder at parentImportFolder with properties {name:notebookName}
				end tell
			end if
			tell application "Notes"
				make new note at notebookFolder with properties {name:"", body:noteContent, creation date:noteCreationDate, modification date:noteModificationDate}
			end tell
			
			set notebookNotesCounter to notebookNotesCounter + 1
			set importedNotesCount to importedNotesCount + 1
			log "Notes #" & importedNotesCount & "/" & allNotesCount & " imported"
			if maxNotesToImport ≥ 0 and importedNotesCount ≥ maxNotesToImport then
				log "Stopping at notes #" & importedNotesCount
				my cleanup()
				error number -128
			end if
		end repeat
	end repeat
	
	my cleanup()
end tell

on getNotesSubFolder(notesFolder, subfolderName)
	tell application "Notes"
		repeat with subfolder in folders in notesFolder
			if name of subfolder is equal to subfolderName then
				return subfolder
			end if
		end repeat
		return null
	end tell
end getNotesSubFolder

on extractStackName(noteTags)
	repeat with noteTag in noteTags
		if name of noteTag starts with stackTagPrefix then
			set tagName to name of noteTag
			set stackName to text ((length of stackTagPrefix) + 1) thru -1 of tagName
			return stackName
		end if
	end repeat
	return null
end extractStackName

on nowYYYYMMDDMMSS()
	set now to (current date)
	set result to (year of now as integer) as string
	set result to result & "-"
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(day of now as integer, 2)
	set result to result & "T"
	set result to result & zero_pad(hours of now as integer, 2)
	set result to result & ":"
	set result to result & zero_pad(minutes of now as integer, 2)
	set result to result & ":"
	set result to result & zero_pad(seconds of now as integer, 2)
	
	return result
end nowYYYYMMDDMMSS

on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad

on writeToFile(this_data, target_file, append_data) -- (string, file path as string, boolean)
	tell application "Finder"
		try
			set the target_file to the target_file as string
			set the open_target_file to open for access file target_file with write permission
			if append_data is false then set eof of the open_target_file to 0
			write this_data to the open_target_file starting at eof
			close access the open_target_file
			return true
		on error errStr number errorNumber
			log "ERROR" & errStr & errorNumber
			try
				close access file target_file
			end try
			return false
		end try
	end tell
end writeToFile

on readFile(theFile)
	-- Convert the file to a string
	set theFile to theFile as string
	-- Read the file and return its contents
	return read file theFile
end readFile

on getNoteContentFromEvernoteNote(evernoteNote)
	tell application "Evernote Legacy"
		set noteContent to HTML content of evernoteNote
		set allAttachments to every attachment in evernoteNote
		-- Pictures attached?
		if (allAttachments is not {}) then
			tell application "System Events" to if (exists file tmpNoteContentPath) then delete file tmpNoteContentPath
			my writeToFile(noteContent, tmpNoteContentPath, false)
			repeat with currentAttachment in allAttachments
				set attachmentHash to hash of currentAttachment
				set attachmentMime to mime of currentAttachment
				
				if attachmentMime contains "image" then
					tell application "System Events" to if (exists file tmpAttachmentFilePath) then delete file tmpAttachmentFilePath
					--log POSIX path of tmpAttachmentFilePath
					currentAttachment write to tmpAttachmentFilePath
					do shell script "openssl base64 -in " & quoted form of POSIX path of tmpAttachmentFilePath & " > " & quoted form of POSIX path of tmpAttachmentB64FilePath
					set prependReplace to "<img style=\"max-width: 100%; max-height: 100%;\" src=\"data:" & attachmentMime & ";base64,"
					do shell script "cat " & quoted form of POSIX path of tmpAttachmentB64FilePath & " | pbcopy && echo '" & prependReplace & "' > " & quoted form of POSIX path of tmpAttachmentB64FilePath & " && pbpaste >> " & quoted form of POSIX path of tmpAttachmentB64FilePath
					do shell script "echo '\"/>' >> " & quoted form of POSIX path of tmpAttachmentB64FilePath
					set searchPattern to "<img[^>]*" & attachmentHash & ".*?>"
					
					do shell script "cat " & (quoted form of POSIX path of tmpNoteContentPath) & " | perl -pe 's|" & searchPattern & "|`cat " & quoted form of POSIX path of tmpAttachmentB64FilePath & "`|gme' | pbcopy && pbpaste > " & (quoted form of POSIX path of tmpNoteContentPath)
				else
					if showAttachmentError is true then
						set dialogText to "The note (" & title of evernoteNote & ") has unhandled attachment mime-type: " & attachmentMime & ". Attachment will NOT be imported. Set property showAttachmentError to false to ignore such messages."
						display dialog dialogText
					end if
				end if
			end repeat
			set noteContent to my readFile(tmpNoteContentPath)
		end if
		
		return noteContent
	end tell
end getNoteContentFromEvernoteNote

on cleanup()
	-- delete temp files for pictures attachment base 64 conversion
	tell application "Finder"
		if (exists file tmpNoteContentPath) then delete file tmpNoteContentPath
		if (exists file tmpAttachmentFilePath) then delete file tmpAttachmentFilePath
		if (exists file tmpAttachmentB64FilePath) then delete file tmpAttachmentB64FilePath
	end tell
	-- set clipboard content back to initial content
	do shell script "echo " & quoted form of clipboardContent & " | pbcopy"
end cleanup