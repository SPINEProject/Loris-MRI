#! /usr/bin/perl

=pod

=head1 NAME

run_insert_TransSegs_IPMSA.pl -- a script that inserts a file, tranformation or segmentation, into LORIS.


=head1 SYNOPSIS

C<perl tools/run_insert_TransSegs_IPMSA.pl [options]>

Available options are:

C<-profile>     : name of the config file in C<../dicom-archive/.loris_mri>

C<-candidateId>: Id of the candidate in LORIS C<candidateID>

C<-visitLabel>: Visit label  C<visitLabel>

C<-fileType>: Type of the file to be uploaded C<fileType>

C<-sourcePipeline>: Name of the pipeline used to generate the file to be uploaded C<sourcePipeline>

C<-coordinateSpace>: Coordinate space of the output C<coordinateSpace>

C<-acquisitionLabel>: Acquisitin label of the image to which the file will be attached  C<acquisitionLabel>

C<-filpath>:  Path to the file to be uploaded C<filepath>

C<-tref>:  Transformation reference C<tref>

C<-verbose>     : be verbose


=head1 DESCRIPTION

This script inserts a file, transformation or segmentaiton into LORIS attached to a file. The file is
selected using the candidateId, visitLabel, and acquisition label.

=head1 METHODS

=cut


use strict;
use warnings;
use Getopt::Tabular;
use File::Basename;
use File::Path 'make_path';
use File::Temp 'tempdir';


use NeuroDB::DBI;
# AMP -  Exit codes were not located
# use NeuroDB::ExitCodes;
# PMA

my $profile;
my $profile_desc     = "Name of the config file in ../dicom-archive/.loris_mri";
my $candidateId;
my $candidateId_desc = "Id of the candidate in LORIS.";
my $visitLabel;
my $visitLabel_desc = "Visit label in LORIS.";
my $fileType;
my $fileType_desc = "Type of the file to be uploaded in LORIS.";
my $sourcePipeline;
my $sourcePipeline_desc = "Name of the pipeline used to generate the file to be uploaded.";
my $coordinateSpace;
my $coordinateSpace_desc = "Coordinate space of the output.";
my $acquisitionLabel;
my $acquisitionLabel_desc = "Acquisition label, e.g., t1c, t1p";
my $filepath;
my $filepath_desc = "Filepath to be uploaded";
my $verbose          = 0;

my @opt_table = (
    [ "-profile",    "string",  1, \$profile,     $profile_desc      ],
    [ "-candidateId", "string",  1, \$candidateId, $candidateId_desc ],
    [ "-visitLabel", "string",  1, \$visitLabel, $visitLabel_desc ],
    [ "-fileType", "string",  1, \$fileType, $fileType_desc ],
    [ "-sourcePipeline", "string",  1, \$sourcePipeline, $sourcePipeline_desc ],
    [ "-coordinateSpace", "string",  1, \$coordinateSpace, $coordinateSpace_desc ],
    [ "-acquisitionLabel", "string",  1, \$acquisitionLabel, $acquisitionLabel_desc ],
    [ "-filepath", "string",  1, \$filepath, $filepath_desc ],
    [ "-verbose",    "boolean", 1, \$verbose,     "Be verbose"       ]
);

my $Help = <<HELP;
**********************************************************************************
INSERT SEGMENTATION AND TRANSFORMATION FILES INTO LORIS
**********************************************************************************

HELP

my $Usage = <<USAGE;
Usage: $0 [options]
       $0 -help to list options
USAGE

&Getopt::Tabular::SetHelp($Help, $Usage);

# AMP - Exit codes were not located
# &Getopt::Tabular::GetOptions(\@opt_table, \@ARGV)
#    || exit $NeuroDB::ExitCodes::GETOPT_FAILURE;
&Getopt::Tabular::GetOptions(\@opt_table, \@ARGV)
    || exit "NeuroDB::ExitCodes::GETOPT_FAILURE";
# PMA

## input error checking

if (!$ENV{LORIS_CONFIG}) {
    print STDERR "\n\tERROR: Environment variable 'LORIS_CONFIG' not set\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::INVALID_ENVIRONMENT_VAR;
    exit "NeuroDB::ExitCodes::INVALID_ENVIRONMENT_VAR";
}

if (!defined $profile || !-e "$ENV{LORIS_CONFIG}/.loris_mri/$profile") {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify a valid and existing profile.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::PROFILE_FAILURE";
    exit 101;
    # PMA
}

{ package Settings; do "$ENV{LORIS_CONFIG}/.loris_mri/$profile" }

if ( !@Settings::db ) {
    print STDERR "\n\tERROR: You don't have a \@db setting in the file "
                 . "$ENV{LORIS_CONFIG}/.loris_mri/$profile \n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::DB_SETTINGS_FAILURE;
    exit "NeuroDB::ExitCodes::DB_SETTINGS_FAILURE";
    # PMA
}

if (!defined $candidateId) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify a candidate id.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::CANDIDATE_ID_NOT_SPECIFIED\n\n";
    exit 102;
    # PMA
}

if (!defined $visitLabel) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify a visit label.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::VISIT_LABEL_NOT_SPECIFIED\n\n";
    exit 103;
    # PMA
}

if (!defined $fileType) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify the type of the file.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::FILE_TYPE_NOT_SPECIFIED\n\n";
    exit 103;
    # PMA
}

if (!defined $sourcePipeline) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify the name of the pipeline used to generate the file.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::PIPELINE_NAME_NOT_SPECIFIED\n\n";
    exit 103;
    # PMA
}

if (!defined $coordinateSpace) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify the coodinate space of the file.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::COORDINATE_SPACE_NOT_SPECIFIED\n\n";
    exit 103;
    # PMA
}

if (!defined $acquisitionLabel) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify an acquisition label.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::ACQUISITION_LABEL_NOT_SPECIFIED\n\n";
    exit 104;
    # PMA
}

if (!defined $filepath) {
    print $Help;
    print STDERR "$Usage\n\tERROR: You must specify a file path.\n\n";
    # AMP - Exit codes were not located
    #exit $NeuroDB::ExitCodes::PROFILE_FAILURE;
    print "NeuroDB::ExitCodes::FILEPATH_NOT_SPECIFIED\n\n";
    exit 105;
    # PMA
}

## establish database connection

my $dbh = &NeuroDB::DBI::connect_to_db(@Settings::db);
print "\n==> Successfully connected to the database \n" if $verbose;



## get today's date

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
my $today = sprintf( "%4d-%02d-%02d", $year + 1900, $mon + 1, $mday );


## Get the associated FileID
my $FileID = get_FileID_given_CandID_VisitLabel_AcquisitionLabel($candidateId, $visitLabel, $acquisitionLabel);


## Link the fileregister_file($FileID)
register_file($FileID);

# AMP - Exit codes were not located
#exit $NeuroDB::ExitCodes::SUCCESS;
print "NeuroDB::ExitCodes::SUCCESS";
exit "106";
# PMA


=pod

=head3 get_FileID_given_CandID_VisitLabel_AcquisitionLabel

Returns the FileID associated with the image linked to the candidate (CandID),
visit label (VisitLabel), and label of the acquisition (AcquisitionLabel)

INPUTS: candidate ID, visit label, and acquisition label

RETURNS: The FileID associated with the inputs

=cut

sub get_FileID_given_CandID_VisitLabel_AcquisitionLabel {
    my ($candID, $visitLabel, $acquisitionLabel) = @_;
    #my ($visitLabel) = @_;
    #my ($acquisitionLabel) = @_;

    my $fileLikeName = "%" . $candID . "_" . $visitLabel . "_" . $acquisitionLabel . "%";

    print "fileLikeName:" . $fileLikeName . "\n\n";

    my $query  = "SELECT FileID FROM files WHERE File LIKE ?";
    #my $result = $dbh->selectrow_hashref($query, undef, $fileLikeName);

    # prepare and execute the query
    my $sth   = $dbh->prepare($query);
    $sth->execute($fileLikeName);

    # grep the results
    my ($FileID) = $sth->fetchrow_array;

    #print "result:" . $result;

    #my $FileID     = $result->{'FileID'     };

    print "FileID:" . $FileID . "\n\n";

    return $FileID;
}



=pod

=head3 register_file_t2_lesions_aligned_with_icbm_template($FileID)

Registers t2 lesions aligned with icdm template to the t2 image.

INPUT: FileID 

=cut

sub register_file {
    my ($FileID) = @_;

    my $register_cmd = "register_processed_data.pl "
                       . " -profile $profile "
                       . " -sourcePipeline $sourcePipeline "
                       . " -tool $sourcePipeline "
                       . " -pipelineDate $today "
                       . " -coordinateSpace $coordinateSpace "
                       . " -outputType $fileType "
                       . " -inputFileIDs $FileID "
                       . " -sourceFileID $FileID "
                       . " -scanType $fileType "
                       . " -file $filepath ";


    print "\nCommand line to be executed:" . $register_cmd . "\n\n";

    # register the scan in the DB
    my $exit_code = system($register_cmd);
    if ($exit_code != 0) {
        print "\nAn error occurred when running register_processed_data.pl."
              . " Error Code was: " . $exit_code >> 8 . "Exiting now\n\n";
        # exit $NeuroDB::ExitCodes::PROGRAM_EXECUTION_FAILURE;
        exit 999;
    }
}



=pod
