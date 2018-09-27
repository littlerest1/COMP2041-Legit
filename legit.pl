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

elsif($ARGV[0] eq "init"){
	Initialize();
}

elsif($ARGV[0] eq "add"){
	checkinit();
	addFile();
}

elsif($ARGV[0] eq "commit"){
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

elsif($ARGV[0] eq "show"){
	checkinit();
	checkrepo();
	if($#ARGV != 1){
		print "usage: legit.pl show <commit>:<filename>\n";
		exit 1;
	}
	show();
}

elsif($ARGV[0] eq "log"){
	checkinit();
	checkrepo();
	printCommit();
}

elsif($ARGV[0] eq "branch"){
	checkinit();
	checkrepo();
	if($#ARGV == 0){
		printBranch();
	}
	elsif($#ARGV == 1){
		createBranch($ARGV[1]);
	}
	elsif($#ARGV == 2 && $ARGV[1] eq "-d"){
		deleteBranch($ARGV[2]);
	}
	else{
		print "usage: legit.pl branch [-d] <branch>\n";
		exit 1;
	}
}

elsif($ARGV[0] eq "checkout"){
	checkinit();
	checkrepo();
	if($#ARGV == 1){
		switch($ARGV[1]);
	}
	else{
		print "usage: legit.pl checkout <branch>\n";
		exit 1;
	}
}
elsif($ARGV[0] eq "rm"){
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
elsif($ARGV[0] eq "status"){
	checkinit();
	checkrepo();
	status();
}
else{
	print "legit.pl: error: unknown command @ARGV\n";
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
#functions for each command

#get the current repository
sub getRepo{
	my $firstLine;
	foreach my $dir(glob(".legit/repository/*")){
		#print "$dir\n";
		$firstLine = $dir;
	}
	my @input = split ('_',$firstLine);
	#	print "@input\n";
	my $curr = 0;
	if($input[1] ne ""){
		$curr = $input[1];
	}
	return $curr;
}
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
	
	my $status = '.legit/status.txt';
	unless(open FH, '>'.$status) {
		die "\nUnable to create $status\n";
	}
	close(FH);
	
	my $branch = '.legit/branch.txt';
	unless(open BR, '>'.$branch) {
		die "\nUnable to create $branch\n";
	}
	close(BR);
	
	my $index = ".legit/index";
	unless(mkdir($index)) {
        die "Unable to create $index\n";
    }
	
	my $repository = ".legit/repository";
	unless(mkdir($repository)) {
        die "Unable to create $repository\n";
    }
	
	my $bin = ".legit/bin";
	unless(mkdir($bin)) {
        die "Unable to create $bin\n";
    }
	
	print "Initialized empty legit repository in .legit\n";
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
			#print "$ARGV[$args],$#ARGV,$args\n";	
			if(-d $ARGV[$args]){
				print "legit.pl: error: '$ARGV[$args]' is not a regular file\n";
				exit 1;
			}
			if(-e $ARGV[$args]){
				copy($ARGV[$args],$directory) or die "legit.pl: error: can not open '$ARGV[$args]'\n";
			}
			elsif(-e ".legit/index/$ARGV[$args]"){
			#	print "unlink\n";
				copy(".legit/index/$ARGV[$args]",".legit/bin/$ARGV[$args]") or die "legit.pl: error: can not open '/bin/$ARGV[$args]'\n";
			    unlink ".legit/index/$ARGV[$args]";
			}
            else{
				print "legit.pl: error: can not open '$ARGV[$args]'\n";
			}
			$args ++;
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
		my $commit = ".legit/repository/Commit_0";
		unless(mkdir($commit)) {
			die "Unable to create $commit\n";
		}
		
		open my $state,'>',".legit/status.txt" or die "Could not open status.txt\n";
		my $dir = getcwd;
		
		foreach my $now (glob("$dir/*")){
			my @cho = split ('/',$now);	
			print $state "$cho[$#cho] - untracked\n";
		}
		close $state;
		
		
	#	open my $status,'<',".legit/status.txt" or die "Could not open status.txt\n";
	#	while(my $data = <$status>){
	#		print $data;
	#	} 
	#	close($status);
		
		
		
		
		my $directory = ".legit/index";
		foreach my $file (glob("$directory/*")){
			my @cho = split ('/',$file);	
			changeState($cho[$#cho]);
			copy($file,".legit/repository/Commit_0") or die "legit.pl: error: could not copy '$file'\n";
		}
		
		open my $fh, '>', ".legit/log.txt" or die "Could not open log.txt\n";
		if($#ARGV == 3){
			print $fh "0 $ARGV[3]\n";
		}
		elsif($#ARGV == 2){
			print $fh "0 $ARGV[2]\n";
		}
		print "Committed as commit 0\n";
		close $fh;
		
		open my $br,'>',".legit/branch.txt" or die "Could not open branch.txt\n";
		print $br "1 - master:Commit_0\n";
		close $br;
		
		return;
	}
	else{	
		my $flag = 0;
		my $firstLine = "";
		my @input;
		foreach my $dir(glob(".legit/repository/*")){
			#print "$dir\n";
			$firstLine = $dir;
		}
		if($firstLine ne ""){
			@input = split ('_',$firstLine);
		}
	#	print "@input\n";
		my $count = 0;
		my $curr = 0;
		if(@input ne ""){
			if($input[1] ne ""){
				$curr = $input[1];
			}
		}

		if(looks_like_number($curr)){
			$count = $curr + 1;
		}

		my $directory = ".legit/index";
		if(-e $directory){
			opendir(my $dh, $directory) or die "Not a directory";
			if(scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0 && -z ".legit/log.txt"){
				print "nothing to commit\n";
				close $dh;
				exit 1;
			}
			
			my $commit = ".legit/repository/Commit_$count";
				unless(mkdir($commit)) {
				die "Unable to create $commit\n";
			}
			
			my $num = $curr;
			foreach my $file (glob("$directory/*")){
					my @files = split ('/',$file);
					my $filename = $files[$#files];
				#	print "$filename\n";
					if(checksame($filename,$input[1]) == 1){
						next;
					}
					else{
						foreach my $a (glob("$directory/*")){
							copy($a,".legit/repository/Commit_$count") or die "legit.pl: error: could not copy '$a'\n";
							my @cho = split ('/',$file);	
							changeState($cho[$#cho]);
						}
						$flag = 1;
						last;
					}
			}
			if($flag == 0){
				#print "efoeneio\n";
				#print "$curr\n";
				foreach my $file(glob(".legit/repository/Commit_$curr/*")){
				#	print "$curr\n";
					my @files = split ('/',$file);
					my $filename = $files[$#files];
					if(-e ".legit/index/$filename"){
						#print ".legit/index/$filename\n";
						next;
					}
					else{
						foreach my $a (glob("$directory/*")){
							copy($a,".legit/repository/Commit_$count") or die "legit.pl: error: could not copy '$a'\n";
							my @cho = split ('/',$a);	
							changeState($cho[$#cho]);
						}
						#print "$filename\n";
						$flag = 1;
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
				updateBranch($count);
				print "Committed as commit $count\n";	
			}
			else{
				rmdir ".legit/repository/Commit_$count";
				print "nothing to commit\n";
				exit 1;
			}
		}	
	}
	return;
}

sub changeState{
#	print "$_[0]\n";
	open my $input,".legit/status.txt" or die "Could not open status.txt:$!";

	my @output;
	my $count = 0;
	foreach my $line(<$input>){
		my @words = split(' - ',$line);
		#print "$words[0],";
		if($words[0] eq $_[0]){
			$line =~ s/untracked/same as repo/g;
			$output[$count] = $line;
		}
		else{
			$output[$count] = $line;
		}
		$count ++;
	}
	close $input;

	my $i = 0;

	open(my $FH,'>',".legit/status.txt") or die "Could not open status.txt:$!";

	while($i < $count){
		print $FH "$output[$i]";
		$i ++;
	}
	close $FH;	
	
	return;

}
#check file in both index and repository
sub checksame{
	my ($x, $y) = @_;
	#print "$_[0],$_[1]\n";
	my $commits = ".legit/repository";
	my $count = 0;
	
	if(-e "$commits/Commit_$y/$x"){
		if(compare(".legit/index/$x",".legit/repository/Commit_$y/$x") == 0){
			return 1;
		}
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
		close $fh;
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
		if(!(-e ".legit/repository/Commit_$args[0]")){
			print "legit.pl: error: unknown commit '$args[0]'\n";
			exit 1;
		}
		if(-e ".legit/repository/Commit_$args[0]/$args[1]"){
			open my $fh,'<',".legit/repository/Commit_$args[0]/$args[1]" or die "Could not open .legit/repository/Commit_$args[0]/$args[1]\n";
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
		#print "$ARGV[$#ARGV]\n";
		my $count = 3;
		while($count <= $#ARGV){
			if(-e ".legit/index/$ARGV[$count]"){
				#print "$ARGV[$count]\n";
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
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n";
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
				if(DiffIR($ARGV[$count]) == 0 && DiffCI($ARGV[$count]) == 1){
					print "legit.pl: error: '$ARGV[$count]' in index is different to both working file and repository\n";
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
				#print "here\n";
				if(InRepo($ARGV[$count]) == 1){
					#print "here\n";
					if(DiffIR($ARGV[$count]) == 0 && DiffCI($ARGV[$count]) == 1){
						print "legit.pl: error: '$ARGV[$count]' in index is different to both working file and repository\n";
						exit 1;
					}
					elsif(DiffIR($ARGV[$count]) == 0){
						print "legit.pl: error: '$ARGV[$count]' has changes staged in the index\n";
						exit 1;
					}
					elsif(DiffIR($ARGV[$count]) == 1 && DiffCI($ARGV[$count]) == 1){
						print "legit.pl: error: '$ARGV[$count]' in repository is different to working file\n";
						exit 1;
					}
				}
				else{
					print "legit.pl: error: '$ARGV[$count]' has changes staged in the index\n";
					exit 1;
				}
			}
			else{
				print "legit.pl: error: '$ARGV[$count]' is not in the legit repository\n";
				exit 1;
			}
			$count ++;
		}

		$count = 1;
		while($count <= $#ARGV){
			unlink ".legit/index/$ARGV[$count]";
			unlink "$ARGV[$count]";
			$count ++;
		}
	}
	return;
}

sub DiffIR{
	if(-e ".legit/index/$_[0]"){
		my $curr = getBranch();
		return checksame($_[0],$curr);
	}
	return 0;
}
sub InRepo{
	#print "$_[0]\n";
	my $firstLine;
	foreach my $dir(glob(".legit/repository/*")){
		#print "$dir\n";
		$firstLine = $dir;
	}
	my @input = split ('_',$firstLine);
	#	print "@input\n";
	my $curr = 0;
	if($input[1] ne ""){
		$curr = $input[1];
	}

	foreach my $file(glob(".legit/repository/Commit_$curr/*")){
		my @files = split '/',$file;
		if($files[3] eq $_[0]){
			return 1;
		}
	}
	return 0;
}

sub DiffCI{
	if(-e "$_[0]" && -e ".legit/index/$_[0]"){
		return compare(".legit/index/$_[0]","$_[0]");
	}
	return 1;
}


sub updateS{
	my $dir = getcwd;
	foreach my $file (glob("$dir/*")){
		my @cho = split('/',$file);
		if(-d $cho[$#cho]){
			next;
		}
		elsif(inlist($cho[$#cho]) == 1){
			next;
		}
		else{
			open(my $FH,'>>',".legit/status.txt") or die "Could not open status.txt:$!";
			print $FH "$cho[$#cho] - untracked\n";
			close $FH;
		}
	}
	
	my %hash;
	open my $input,".legit/status.txt" or die "Could not open status.txt:$!";
	#print "second\n";
	foreach my $line(<$input>){
		my @cho = split(' - ',$line);
	#	print "$line";
		if(-d $cho[0]){
			next;
		}
		$hash{$cho[0]} = $line;
	}
	close $input;

	open my $out, '>', ".legit/status.txt.temp" or die "Can't write new file: $!";
	foreach my $key(sort keys %hash){
		print $out "$hash{$key}";
	}
	close $out;
	rename (".legit/status.txt.temp", ".legit/status.txt") or die "Unable to rename: $!";
	
	return;
}

sub inlist{
#	print "inlist=$_[0]\n";
	open my $list,'<',".legit/status.txt" or die "Could not open status.txt:$!";
	
	while(my $x = <$list>){
		my @cho = split(' - ',$x);
		if($cho[0] eq $_[0]){
			return 1;
		}
	}
	close $list;
	return 0;
}

sub status{
	open my $input,".legit/status.txt" or die "Could not open status.txt:$!";
	
	my @output;
	my $count = 0;
	foreach my $line(<$input>){
		my @cho = split(' - ',$line);
		if(-d $cho[0]){
			next;
		}
		if(-e $cho[0]){
			#print "$cho[0]\n";
			if(-e ".legit/index/$cho[0]"){
				my $curr = getRepo();
				#print "$curr\n";
				if(-e ".legit/repository/Commit_$curr/$cho[0]"){
				#	print "all in\n";

					if(DiffCI($cho[0]) == 0 && DiffIR($cho[0]) == 0){
						$line = "$cho[0] - file changed, changes staged for commit\n";
					}
					elsif(DiffCI($cho[0]) == 1 && DiffIR($cho[0]) == 1){
						$line = "$cho[0] - file changed, changes not staged for commit\n";
					}
					elsif(DiffCI($cho[0]) == 1 && DiffIR($cho[0]) == 0){
						$line = "$cho[0] - file changed, different changes staged for commit\n";
					}
					else{
						$line = "$cho[0] - same as repo\n";
					}
				}
				else{
					$line = "$cho[0] - added to index\n";
				}
			}
			else{
				$line = "$cho[0] - untracked\n";
			}
		}
		elsif(-e ".legit/index/$cho[0]"){
			$line = "$cho[0] - file deleted\n"; 
		}
		else{
			my $curr = getRepo();
			if(-e ".legit/repository/Commit_$curr/$cho[0]"){
				$line = "$cho[0] - deleted\n";
			}
			else{
				$line = "";
			}
		}
		$output[$count] = $line;
		$count ++;
	}
	close $input;

	my $i = 0;

	open(my $FH,'>',".legit/status.txt") or die "Could not open status.txt:$!";

	while($i < $count){
		print $FH "$output[$i]";
		$i ++;
	}

	close $FH;
	updateS();
	open(my $out,'<',".legit/status.txt") or die "Could not open status.txt\n";
	while(my $output = <$out>){
		print "$output";
	}
	close $out;
	return;
}
sub updateBranch(){
	open my $in, '<', ".legit/branch.txt" or die "Could no open branch.txt\n";
	open my $out, '>', ".legit/branch.txt.temp" or die "Can't write new file: $!";

	while (my $line = <$in>){
		my @B = split(':',$line);
		if($B[0] =~ m/ - /){
			my @nam = split(' - ',$B[0]);
			print $out "1 - $nam[1]:Commit_$_[0]\n";
		}
		else{
			print $out "$line";
		}
	}
	close $in;
	close $out;
	rename (".legit/branch.txt.temp", ".legit/branch.txt") or die "Unable to rename: $!";
	return;
}
sub printBranch{
	open my $br,'<',".legit/branch.txt" or die "Could not open branch.txt\n";
	
	while(my $line = <$br>){
		my @act = split(':',$line);
		if($act[0] =~ m/ - /){
			my @cho = split(' - ',$act[0]);
			print "$cho[1]\n";
		}
		else{
			print "$act[0]\n";
		}
	}
	close $br;
	return;
}

sub getBranch{
	open my $br,'<',".legit/branch.txt" or die "Could not open branch.txt\n";
	
	while(my $line = <$br>){
		my @act = split(':',$line);
		if($act[0] =~ m/ - /){
			my @cho = split('_',$act[1]);
			my $result = $cho[1] =~ s/\n//gr;
			return $result;
		}
	}
	close $br;
	return 0;
}
sub existsBranch{
	open my $br,'<',".legit/branch.txt" or die "Could not open branch.txt\n";
	
	while(my $line = <$br>){
		my @ac = split(':',$line);
		if($ac[0] =~ m/ - /){
			my @ch = split(' - ',$ac[0]);
			if($ch[1] eq $_[0]){
				close $br;
				return 1;
			}
		}
		else{
			if($ac[0] eq $_[0]){
				close $br;
				return 1;
			}
		}
	}
	close $br;
	return 0;
}
sub createBranch{
	if(existsBranch($_[0]) == 1){
		print "legit.pl: error: branch '$_[0]' already exists\n";
		exit 1;
	} 
	
	my $master = "";
	open(my $FH,'<',".legit/branch.txt") or die "Could not open branch.txt:$!";
	while(my $line = <$FH>){
		my @a = split(':',$line);
		if($a[0] =~ m/ - /){
			my @c = split(' - ',$a[0]);
			if($c[1] eq "master"){
				$master = $a[1];
				last;
			}
		}
		else{
			if($a[0] eq "master"){
				$master = $a[1];
				last;
			}
		}
	}
	close $FH;
	
	open(my $F,'>>',".legit/branch.txt") or die "Could not open branch.txt:$!";
	print $F "$_[0]:$master";
	close $F;
	
	my %hash;
	open my $input,".legit/branch.txt" or die "Could not open branch.txt:$!";
	#print "second\n";
	foreach my $line(<$input>){
		my @BN = split(':',$line);
		if($BN[0] =~ m/ - /){
			my @Bname = split(' - ',$BN[0]);
			$hash{$Bname[1]} = $line;
		}
		else{
			$hash{$BN[0]} = $line;
		}
	}
	close $input;

	open my $out, '>', ".legit/branch.txt.temp" or die "Can't write new file: $!";
	foreach my $key(sort keys %hash){
		print $out "$hash{$key}";
	}
	close $out;
	rename (".legit/branch.txt.temp", ".legit/branch.txt") or die "Unable to rename: $!";
	return;
}


sub unMerge{
	open my $br,'<',".legit/branch.txt" or die "Could not open branch.txt\n";
	
	my $result = "";
	while(my $line = <$br>){
		my @ac = split(':',$line);
		if($ac[0] =~ m/ - /){
			my @ch = split(' - ',$ac[0]);
			if($ch[1] eq $_[0]){
				$result = $ac[1];
				chomp $result;
				last;
			}
		}
		else{
			if($ac[0] eq $_[0]){
				$result = $ac[1];
				chomp $result;
				last;
			}
		}
	}
	close $br;
	
	#print "$result\n";
	if($result ne ""){
		my $dir = getcwd;
		foreach my $file(glob("$dir/*")){
			my @filename = split('/',$file);
			if(-e ".legit/repository/$result/$filename[$#filename]"){
				next;
			}
			else{
				return 1;
			}
		}
	}
	return 0;
}
sub deleteBranch{
	if(existsBranch($_[0]) == 0){
		print "legit.pl: error: branch '$_[0]' does not exist\n";
		exit 1;
	}
	
	if($_[0] eq "master"){
		print "legit.pl: error: can not delete branch 'master'\n";
		exit 1;
	}
	open my $in, '<', ".legit/branch.txt" or die "Could no open branch.txt\n";
	open my $out, '>', ".legit/branch.txt.temp" or die "Can't write new file: $!";

	while (my $line = <$in>){
		my @B = split(':',$line);
		if($B[0] =~ m/ - /){
			my @nam = split(' - ',$B[0]);
			if($nam[1] eq $_[0]){
				my $current = getcwd;
				print "legit.pl: error: internal error error: Cannot delete branch '$_[0]' checked out at '$current/.legit'
 
You are not required to detect this error or produce this error message.\n";
				exit 1;
			}
			elsif(unMerge($_[0]) == 1){
				print "legit.pl: error: branch '$_[0]' has unmerged changes\n";
				exit 1;
			}
			else{
				print $out "$line";	
			}
		}
		elsif($B[0] eq $_[0]){
			next;
		}
		else{
			print $out "$line";
		}
	}
	close $in;
	close $out;
	rename (".legit/branch.txt.temp", ".legit/branch.txt") or die "Unable to rename: $!";
	print "Deleted branch '$_[0]'\n";
	return;
}

sub checkWork{
	#print "$_[0],$_[1]\n";
	foreach my $file(glob(".legit/repository/$_[0]/*")){
		my @files = split('/',$file);
		#print "$file\n";
		#print "$files[$#files]\n";
		if(-e ".legit/repository/$_[1]/$files[$#files]"){
			next;
		}
		else{
			if(-e $files[$#files]){
				unlink $files[$#files];
			}
		}
	}
	
	if($_[0] ne $_[1]){
		my $dir = getcwd;
		foreach my $f(glob(".legit/repository/$_[1]/*")){
			#print "$f\n";
			my @filename = split('/',$f);
			if(-e "$dir/$filename[$#filename]"){
				if(DiffCI($filename[$#filename]) == 1 && DiffIR($filename[$#filename]) == 0){
					print "legit.pl: error: Your changes to the following files would be overwritten by checkout:\n$filename[$#filename]\n";
					unlink ".legit/branch.txt.temp";
					exit 1;
				}
			}
			copy($f,$dir) or die "Could not copy $f\n";
			copy($f,".legit/index") or die "Could not copy $f\n";
		}
	}
	return;
}

sub switch{
	if(existsBranch($_[0]) == 0){
		print "legit.pl: error: unknown branch '$_[0]'\n";
		exit 1;
	}
	
	my $target = "";
	my $currentB = "";
	open my $in, '<', ".legit/branch.txt" or die "Could no open branch.txt\n";
	open my $out, '>', ".legit/branch.txt.temp" or die "Can't write new file: $!";

	while (my $line = <$in>){
		my @B = split(':',$line);
		if($B[0] =~ m/ - /){
			my @nam = split(' - ',$B[0]);
			if($nam[1] eq $_[0]){
				print "Already on '$_[0]'\n";
				exit 1;
			}
			else{
				$currentB = $B[1];
				print $out "$nam[1]:$B[1]";
			}
		}
		elsif($B[0] eq $_[0]){
			$target = $B[1];
			print $out "1 - $B[0]:$B[1]";
		}
		else{
			print $out "$line";
		}
	}
	close $in;
	close $out;
	#rename (".legit/branch.txt.temp", ".legit/branch.txt") or die "Unable to rename: $!";
	
	if($target ne "" && $currentB ne ""){
		chomp $target;
		chomp $currentB;
		checkWork($currentB,$target);
	}
	rename (".legit/branch.txt.temp", ".legit/branch.txt") or die "Unable to rename: $!";
	print "Switched to branch '$_[0]'\n";	
	return;
}