# evernote2applenotes
AppleScript to import Evernote notes to Apple Notes

## Description
This Apple Script automates importing process from Evernote notes to Apple Notes application.

This differs from some scripts available out there by replicating Evernote Stacks hierarchy and supporting notes embedded pictures

## Prerequisites

* MacOS computer (not compatible with Windows / Linux)
* Evernote Legacy application (not the recent Evernote application as it lacks AppleScript support)

## Installation

1. Download Apple Script Evernote2AppleNotes.scpt
2. Edit Evernote2AppleNotes.scpt to define parameters accordingly (see Configuration section)
3. Download [Evernote Legacy](https://help.evernote.com/hc/en-us/articles/360052560314) application 
4. Execute Evernote2AppleNotes.scpt Apple Script. Script logs messages to reflect progress made during the import process (activate messages panel by clicking the proper icon in the bottom toolbar)

## Configuration

MailArchiver.scpt must be edited to match your configuration:

| Key | Default | Description |
| --- | --- | --- |
| `maxNotesToImport` | -1 | Number of notes to import before aborting process. Usefull for testing/validation purposes before performing full import. `-1` to import every notes|
| `showAttachmentError` | true | Only images are supported as Evernote notes' attachment. If an attachment not considered as an image is found within a note then a warning message will be displayed. `false` to deactivate this "non image" warning dialog.|
| `stackTagPrefix` | stack: | Evernote tags value prefix to mimic Evernote Stack structure. See Notes section below|

## Notes

* On my setup, script performs a 1,000 notes import in ca. 45 minutes.
* Apple Notes imported notes are placed into a folder named "_ImportedNotesYYYYMMMDDTHHMMSS". You can then reorganize folder as you which. Apple Notes supports nested folders.
* Before you launch your first import, I recommend you to set `maxNotesToImport` to 10 in order to validate the whole process works and fits your need.
* Non-picture attachments (eg. PDF) from Evernote are not supported.
* Evernote Stack structure is mimicked by leveraging Evernote Tags feature. For reflecting Evernote Stack/Notebook structure into Apple Notes as 2 folders hierarchy (StackFolder/NotebookFolder), assign "stack:XYZ" tags to your Stack's notes. To do so, in Evernote application, click on a given Stack in the left navigation panel. then select all Stack's notes by pressing Command+A keys (or Edit > Select all menu). Finally, Evernote shows a panel on the right hand side in which you can assign Tags. Enter a Tag name starting by "stack:" followed by stack name. e.g. "stack:Work". Repeat this process for all your Stacks (hopefully you don't have that many).
* For embedded pictures to show up in imported Apple Notes notes you will need to Quit then re-Launch Apple Notes application.
* Script converts Evernote attached pictured into Base64 content to embed into Apple Notes notes. This process requires to create temporary files (into user's desktop folder) and to transfer data through the clipboard (copy/paste). Upon script completion, temporary files are deleted and clipboard restored to its original state.
