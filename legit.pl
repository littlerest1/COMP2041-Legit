#!/usr/bin/perl -w

use strict;
use warnings;
use Cwd;
use File::Copy;
use File::Compare;
use Scalar::Util qw(looks_like_number);
use autodie;
use v5.10;

if($#ARGV <= -1){
	print "Usage: legit.pl <command> [<args>]\n\n";
	print "These are the legit commands:\n";
	print "   init       Create an empty legit repository
   add        Add file contents to the index
   commit     Record changes to the repository
   log        Show commit log
   show       Show file at particular state
   rm         Remove files from the current directory and from the index
   status     Show the status of files in the current directory, index, and repository
   branch     list, create or delete a branch
   checkout   Switch branches or restore current directory files
   merge      Join two development histories together\n\n";
	exit 1;
}

if($ARGV[0] eq "init"){
	Initialize();
}

if($ARGV[0] eq "add"){
	checkinit();
	addFile();
}

if($ARGV[0] eq "commit"){
	if($ARGV[1] eq "-m" && $#ARGV == 2){
		checkinit();
		checkindex();	
        commit();	
	}
	elsif($ARGV[1] eq "-a" && $ARGV[2] eq "-m" && $#ARGV == 3){
		checkinit();
		checkindex();
        commitAll();	
	}
	else{
		print "usage: legit.pl commit [-a] -m commit-message\n";
		exit 1;
	}
}

if($ARGV[0] eq "show"){
	checkinit();
	checkrepo();
	if($#ARGV != 1){
		print "usage: legit.pl show <commit>:<filename>\n";
		exit 1;
	}
	show();
}

if($ARGV[0] eq "log"){
	checkinit();
	checkrepo();
	printCommit();
}

if($ARGV[0] eq "rm"){
	checkinit();
	checkrepo();
	if($#ARGV == 0){
		print "legit.pl: error: internal error usage: git rm [<options>] [--] <file>...

    -n, --dry-run         dry run
    -q, --quiet           do not list removed files
    --cached              only remove from the index
    -f, --force           override the up-to-date check
    -r                    allow recursive removal
    --ignore-unmatch      exit with a zero status even if nothing matched

 
You are not required to detect this error or produce this error message.\n";
	exit 1;
	}
	remove();

}
#functions for each command

#check whether initialize legit or not
sub checkinit{
	if(-e ".legit"){
		return;
	}
	else{
		print "legit.pl: error: no .legit directory containing legit repository exists\n";
		exit 1;	
	}
	return;
}

#check whether has any commit or not
sub checkrepo{
	if(-z ".legit/log.txt"){
		print "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	}
	return;
}

sub checkindex{
    opendir(my $dh, ".legit/index") or die "Not a directory";
	if(scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0 && -z ".legit/log.txt"){
		print "nothing to commit\n";
		exit 1;
	}
			
	return;
}
#init function creates folder:.legit/index/log.txt/repository
sub Initialize{
	my $directory = ".legit";
	if(-e $directory){
		print "legit.pl: error: .legit already exists\n";
		exit 1;
	}	
	
	unless(mkdir($directory)) {
        die "Unable to create $directory\n";
    }
	my $filename = '.legit/log.txt';
	unless(open FILE, '>'.$filename) {
		die "\nUnable to create $filename\n";
	}
	close(FILE);
	print "Initialized empty legit repository in .legit\n";
	
	my $index = ".legit/index";
	unless(mkdir($index)) {
        die "Unable to create $index\n";
    }
	
	my $repository = ".legit/repository";
	unless(mkdir($repository)) {
        die "Unable to create $index\n";
    }
	return;
}

#add file to index folder
sub addFile{
	my $directory = ".legit/index";
	if(-e $directory){
		if($#ARGV == 0){
			print "legit.pl: error: internal error Nothing specified, nothing added.\n";
			print "Maybe you wanted to say 'git add .'?\n\n";
			print "You are not required to detect this error or produce this error message.\n";
			exit 1;
		}
		my $args = 1;
		while($args <= $#ARGV){
			#print "$ARGV[$args]\n";	
			if(-d $ARGV[$args]){
				print "legit.pl: error: '$ARGV[$args]' is not a regular file\n";
				exit 1;
			}
			if(-e $ARGV[$args]){
				copy($ARGV[$args],$directory) or die "legit.pl: error: can not open '$ARGV[$args]'\n";
			}
			elsif(-e ".legit/index/$ARGV[$args]"){
			    unlink ".legit/index/$ARGV[$args]";
				#next;
			}
            else{
				print "legit.pl: error: can not open '$ARGV[$args]'\n";
			}
			$args += $args;
		}
	}
	else{
		print "legit.pl: error: no .legit directory containing legit repository exists\n";
		exit 1;
	}
	return;
}

#copy file from index folder to repository folder
sub commit{
	#print "message:$ARGV[2]\n";
	
	if(-z ".legit/log.txt"){
		my $commit = ".legit/repository/Commit0";
		unless(mkdir($commit)) {
			die "Unable to create $commit\n";
		}
		my $directory = ".legit/index";
		foreach my $file (glob("$directory/*")){
			copy($file,".legit/repository/Commit0") or die "legit.pl: error: could not copy '$file'\n";
		}
		open my $fh, '>', ".legit/log.txt" or die "Could no open log.txt\n";
		if($#ARGV == 3){
			print $fh "0 $ARGV[3]\n";
		}
		elsif($#ARGV == 2){
			print $fh "0 $ARGV[2]\n";
		}
		print "Committed as commit 0\n";
		close $fh;
		return;
	}
	else{	
		my $flag = 0;
		open my $fh, '<', ".legit/log.txt" or die "Could no open log.txt\n";
		my $firstLine;
		my $count = 0;
		while( my $line = <$fh> ) {
			if($count == 0){
				$firstLine = $line;
			}
			$count ++;
		}
		my @input = split (' ',$firstLine);
		$count = 0;
		my $curr = 0;
		if($input[0] ne ""){
			$curr = $input[0];
		}

		if(looks_like_number($curr)){
			$count = $curr + 1;
		}
		close $fh;
		
		my $directory = ".legit/index";
		if(-e $directory){
			opendir(my $dh, $directory) or die "Not a directory";
			if(scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0 && -z ".legit/log.txt"){
				print "nothing to commit\n";
				close $dh;
				exit 1;
			}
			
			my $commit = ".legit/repository/Commit$count";
				unless(mkdir($commit)) {
				die "Unable to create $commit$count\n";
			}
			
			my $num = $curr;
			while($num >= 0){
				foreach my $file(glob(".legit/repository/Commit$num/*")){
				#	print "loop\n";
					my @files = split '/',$file;
					if(-e ".legit/index/$files[$#files]"){
						#print "find\n";
						next;
					}
					else{
						unlink ".legit/repository/Commit$num/$files[$#files]";
					#	copy($a,".legit/repository/Commit$count") or die "legit.pl: error: could not copy '$a'\n";
						$flag = 1;
						#last;
					}
				
				}
				$num --;
			}
			
			if($flag == 0){
				foreach my $file (glob("$directory/*")){
					my @files = split ('/',$file);
					my $filename = $files[$#files];
					#print "$filename\n";
					if(checksame($filename,$input[0]) == 1){
						next;
					}
					else{
						foreach my $a (glob("$directory/*")){
							copy($a,".legit/repository/Commit$count") or die "legit.pl: error: could not copy '$a'\n";
						}
						$flag = 1;
						last;
					}
				}
			}
			if($flag == 1){
				open my $in, '<', ".legit/log.txt" or die "Could no open log.txt\n";
				open my $out, '>', ".legit/log.txt.temp" or die "Can't write new file: $!";
				if($#ARGV == 3){
					print $out "$count $ARGV[3]\n";
				}
				elsif($#ARGV == 2){
					print $out "$count $ARGV[2]\n";
				}
				while (my $line = <$in>){
					print $out "$line";
				}
				close $in;
				close $out;
				rename (".legit/log.txt.temp", ".legit/log.txt") or die "Unable to rename: $!";
				print "Committed as commit $count\n";	
			}
			else{
				rmdir ".legit/repository/Commit$count";
				print "nothing to commit\n";
				exit 1;
			}
		}	
	}
	return;
}

#check file in both index and repository
sub checksame{
	#print "$_[0],$_[1]\n";
	my $commits = ".legit/repository";
	my $count = 0;
	
	while($count <= $_[1]){
		foreach my $file (glob("$commits/Commit$count/*")){
			my @files = split ('/',$file);
			my $filename = $files[$#files];
			if($filename eq $_[0]){
				if(compare(".legit/index/$filename",".legit/repository/Commit$count/$filename") == 0){
					return 1;
				}
			}
		}
		$count ++;
	}
	return 0;

}

#print commit message functions(print log.txt)
sub printCommit{
	if(-e ".legit/log.txt"){
		if(-z ".legit/log.txt"){
			print "legit.pl: error: your repository does not have any commits yet\n";
			exit 1;
		}
		open my $fh, ".legit/log.txt" or die "Could not open:.legit/log.txt";
		
		while( my $line = <$fh> ) {
			print "$line";
		}
		close($fh);
	}
	else{
		print "legit.pl: error: no .legit directory containing legit repository exists\n";
		exit 1;
	}
	return;
}

#show function,print lines of given file
sub show{
	my @args = split ':',$ARGV[1];
	#print "$args[0]\n";
	#print "$args[1]\n";
	if(looks_like_number($args[0])){
		#print "$args[0]\n";
		if(!(-e ".legit/repository/Commit$args[0]")){
			print "legit.pl: error: unknown commit '$args[0]'\n";
			exit 1;
		}
		if(-e ".legit/repository/Commit$args[0]/$args[1]"){
			open my $fh,'<',".legit/repository/Commit$args[0]/$args[1]" or die "Could not open .legit/repository/Commit$args[0]/$args[1]\n";
			while(my $line = <$fh>){
				print "$line";
			}
			close $fh;
		}
		else{
			print "legit.pl: error: '$args[1]' not found in commit $args[0]\n";	
			exit 1;
		}
	}
	else{
		if(-e ".legit/index/$args[1]"){
			open my $fh,'<',".legit/index/$args[1]" or die "Could not open .legit/index/$args[1]\n";
			while(my $line = <$fh>){
				print "$line";
			}
			close $fh;
		}
		else{
			print "legit.pl: error: '$args[1]' not found in index\n";
			exit 1;
		}
	}
	return;
}

sub commitAll{
	foreach my $file((glob(".legit/index/*"))){
		my @files = split ('/',$file);
		my $filename = $files[$#files];
		#print "$filename\n";
		if(-e "$filename"){
			copy($filename,".legit/index/$filename") or die "legit.pl: error: could not copy '$filename'\n";
		}
	}
	commit();
    return;
}



sub remove{
	my $flag = 0;
	my $f2 = 0;
	foreach my $args(@ARGV){
		if($args =~ m/--force/){
			$flag = 1;
		}
		if($args =~ m/--cached/){
			$f2 = 1;
		}
	}
	foreach my $args(@ARGV){
		if($flag == 0 && $f2 == 0 && $args =~ m/--/){
			print "usage: legit.pl rm [--force] [--cached] <filenames>\n";
			exit 1;
		}
	}
	#cached and force request remove the file from index folder without checking differences
	if($flag == 1 && $f2 == 1){
		print "$ARGV[$#ARGV]\n";
		my $count = 3;
		while($count <= $#ARGV){
			if(-e ".legit/index/$ARGV[$count]"){
				print "$ARGV[$count]\n";
				unlink ".legit/index/$ARGV[$count]";
			}
			else{
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n";
				exit 1;
			}
			$count ++;
		}
	}
	#force request remove file from index and current directory without checking differences
	elsif($flag == 1){
		my $count = 2;
		while($count <= $#ARGV){
			if(-e ".legit/index/$ARGV[$count]"){
				unlink ".legit/index/$ARGV[$count]";
				if(-e "$ARGV[$count]"){
					unlink "$ARGV[$count]";
				}
			}
			else{
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n;";
				exit 1;
			}
			$count ++;
		}
	}
	#cached request check the file in index and repository folder, if there are different error message otherwise delete from index folder
	elsif($f2 == 1){
		my $count = 2;
		while($count <= $#ARGV){
			if(-e ".legit/index/$ARGV[$count]"){
					#print "here\n";
				if(DiffCI($ARGV[$count]) == 1){
					print "legit.pl: error: '$ARGV[$count]' in repository is different to working file\n";
					exit 1;
				}
				else{
					unlink ".legit/index/$ARGV[$count]";
				}
			}
			else{
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n";
				#exit 1;
			}
			$count ++;
		}
	}
	#no cached and force check the file in index and repository folder,if there are different error message,otherwise delete from index and current directory
	else{
		my $count = 1;
		while($count <= $#ARGV){
			if(-e ".legit/index/$ARGV[$count]"){
				if(InRepo($ARGV[$count]) == 1){
					#print "here\n";
					if(DiffIR($ARGV[$count]) == 0){
						print "legit.pl: error: '$ARGV[$count]' has changes staged in the index\n";
						exit 1;
					}
					elsif(DiffIR($ARGV[$count]) == 0 && DiffCI($ARGV[$count]) == 0){
						print "legit.pl: error: '$ARGV[$count]' in index is different to both working file and repository\n";
						exit 1;
					}
					elsif(DiffIR($ARGV[$count]) == 1 && DiffCI($ARGV[$count]) == 1){
						print "legit.pl: error: '$ARGV[$count]' in repository is different to working file\n";
						exit 1;
					}
					else{
						#print "unlink all\n";
						unlink ".legit/index/$ARGV[$count]";
						unlink "$ARGV[$count]";
					}
				}
				else{
					print "legit.pl: error: '$ARGV[$count]' has changes staged in the index\n";
					exit 1;
				}
			}
			else{
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n";
			}
			$count ++;
		}
	}
	return;
}

sub DiffIR{
	if(-e ".legit/index/$_[0]"){
		open my $fh, '<', ".legit/log.txt" or die "Could no open log.txt\n";
		my $firstLine;
		my $count = 0;
		while( my $line = <$fh> ) {
			if($count == 0){
				$firstLine = $line;
			}
			$count ++;
		}
		my @input = split (' ',$firstLine);
		my $curr = 0;
		if($input[0] ne ""){
			$curr = $input[0];
		}
		return checksame($_[0],$curr);
	}
	return 0;
}
sub InRepo{
	#print "$_[0]\n";
	open my $fh, '<', ".legit/log.txt" or die "Could no open log.txt\n";
	my $firstLine;
	my $count = 0;
	while( my $line = <$fh> ) {
		if($count == 0){
			$firstLine = $line;
		}
		$count ++;
	}
	my @input = split (' ',$firstLine);
	my $curr = 0;
	if($input[0] ne ""){
		$curr = $input[0];
	}

	while($curr >= 0){
		foreach my $file(glob(".legit/repository/Commit$curr/*")){
			my @files = split '/',$file;
			if($files[3] eq $_[0]){
				return 1;
			}
		}
		$curr --;
	}
	return 0;
}

sub DiffCI{
	if(-e "$_[0]" && -e ".legit/index/$_[0]"){
		return compare(".legit/index/$_[0]","$_[0]");
	}
	return 1;
}