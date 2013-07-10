#!/usr/bin/perl

use Cwd;

#####################
## Default Profile ##
#####################

$sImageDir 	= "/home/evilmaniac/Documents/updater-test";
$sDirPrefix 	= "l4d2_";
$sPrimaryImage 	= "00";

# FileLists should not contain a forward slash at the beginning
# e.g:
# Instead of using "./direcotry/xyz" use "directory/xyz"

$sLogFileDir = "left4dead2/addons/sourcemod/logs";

@sConfigFileList = (
	"start*",
	"left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg",
	"left4dead2/cfg/Server.cfg"
);

@sLogFileList = (
	"-C left4dead2/addons/sourcemod/logs ."
);

@sPayloadFileList = (
	"left4dead2/addons",
	"left4dead2/cfg/em_cfg",
	"left4dead2/cfg/Server.cfg",
	"left4dead2/cfg/sourcemod",
	"left4dead2/em_motd.txt",
	"left4dead2/em_host.txt"
);

###############
## Variables ##
###############

$sVersion = "0.1 [BETA]";

%hFunctions = (
	'help' 		=> \&DisplayHelp,
	'scan' 		=> \&ListInstallations,
	'echo' 		=> \&Echo,
	'genconf' 	=> \&GenConf,
	'genpayload'	=> \&GenPayload,
	'genlogarchive'	=> \&GenLogArchive,
        'exit' 		=> \&Exit,
);

&CommandInput();

#############
## Console ##
#############

sub CommandInput(){
	print "updater -> ";
        $usrCommand = <>;
        &ProcessCommand($usrCommand);
}

sub ProcessCommand(){
	my($usrInput) = $_[0];
	$usrInput =~ s/\n//;

	my(@usrTokens) = split(/\s+/,$usrInput);
	$usrCommand = shift(@usrTokens);

        if (exists $hFunctions{$usrCommand}){ &{$hFunctions{$usrCommand}}(@usrTokens); }
        else { print "Command not found\n"; }

        &CommandInput();
}

############
## Engine ##
############

# executes a shell command
sub exeSysCmd(){
	my($sCmd) = @_;
	system("$sCmd\n");
	return;
}
# compresses given files into a tar archive
sub compressTar(){
	my($sDestination, $sArchiveName, $sFiles) = @_;
	&exeSysCmd("tar -zcvf $sDestination/$sArchiveName.tar.gz $sFiles");
	return;
}
# returns a list of all installation images
sub getInstallations(){
	return <$sImageDir/$sDirPrefix*>;
}
# prints an error message to the user
sub printError(){
	my($sErrorMsg) = @_;
	print("Error: $sErrorMsg\n");
	return;
}
# returns date in the YYYY.MM.DD format
sub getDate(){
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900; # Year is returned as a value starting from 1900, therefore we must
		       # add 1900 to calculate present date.
	$mon += 1;     # Months start from 0, therefore we must add 1
	return("$year.$mon.$mday");
}
# checks whether or not an installation folder
# is a primary installation image or not. Returns
# 1 if it is, 0 otherwise
sub isPrimary(){
	my($sDirName) = @_;
	if($sDirName eq $sDirPrefix.$sPrimaryImage){
		return 1;
	} else{
		return 0;
	}
}

##############
## Commands ##
##############

##
# Displays each command currently available
#
##
sub DisplayHelp(){
	print "eM-Update | $sVersion\n\nCommands:\n";
	foreach my $Key (keys %hFunctions){ print $Key."\n"; }
	return;
}
##
# Lists all installations in the $sImageDir directory including
# primary installation and all forked installations
##
sub ListInstallations(){
	my @sDirs = getInstallations();
	foreach $sDir (@sDirs){
		print($sDir."\n");
	}
	return;
}

sub Echo(){
	foreach my $Token (@_){ print $Token." "; }
	print "\n";
	return;
}
##
# Generates configuration file images from the forked installation
# images. Includes all files in the @sConfigFileList array
##
sub GenConf(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image number
		if(&isPrimary($1)) { next; } # Skip primary installation image
		#&exeSysCmd("tar -zvcf $sCwd/$1.tar.gz ".join(' ', @sConfigFileList));
		&compressTar($sCwd, $1, join(' ', @sConfigFileList));
	}
	chdir($sCwd);
	return;
}
###
# Generated a back up of each server's log files
# TODO chdir must change to absolute directory path (where the logs are stored)
###
sub GenLogArchive(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image number
		if(&isPrimary($1)) { next; } # Skip primary installation image
		&exeSysCmd("mkdir -p $sCwd/logs/$1");
		#&exeSysCmd("tar -zvcf $sCwd/logs/$1/log-$1-".&getDate().".tar.gz -C $sLogFileDir");
		&compressTar("$Cwd/logs/$1", "log-$1-".&getDate(), "-C $sLogFileDir");
	}
	chdir($sCwd);
	return;
}
##
# Generates a payload image from the primary installation
# Includes all files dictated in the @sPayloadFileList array
##
sub GenPayload(){
	my $sCwd = getcwd();

	chdir($sImageDir.'/'.$sDirPrefix.$sPrimaryImage);
	#&exeSysCmd("tar -zvcf $sCwd/em_payload-".&getDate().".tar.gz ".join(' ', @sPayloadFileList));
	&compressTar($sCwd, "em_payload-".&getDate(), join(' ', @sPayloadFileList));
	chdir($sCwd);
}
##
# Terminates the application
#
##
sub Exit(){
        print("Terminating. . .\n");
	exit(0);
}
