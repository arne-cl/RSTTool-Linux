
## PATCH to AVOID THE tk_getOpenFile double-click problem
# Fix suggested by Bob Sheskey (rsheskey@ix.netcom.com) 1997
# Packaged into a code patch by Mick O'Donnell (micko@wagsoft.com) 2001
# 


global tcl_platform
if { $tcl_platform(platform) == "windows"} {

    # Don't move the original procs twice
    if { [info commands orig_tk_getOpenFile] == {}} {
	
	# Rename the procs elsewhere
	rename tk_getOpenFile orig_tk_getOpenFile
	rename tk_getSaveFile orig_tk_getSaveFile
    }
    
    # Provide a new definitions
    proc tk_getOpenFile {args} {
	if [winfo exists .temp787] {destroy .temp787}
	wm withdraw [toplevel .temp787]
	grab .temp787
	set file [eval [concat orig_tk_getOpenFile $args]]
	update
	destroy .temp787
	return $file
    }
    
    proc tk_getSaveFile {args} {
	if [winfo exists .temp787] {destroy .temp787}
	wm withdraw [toplevel .temp787]
	grab .temp787
	set file [eval [concat orig_tk_getSaveFile $args]]
	update
	destroy .temp787
	return $file
    }
}