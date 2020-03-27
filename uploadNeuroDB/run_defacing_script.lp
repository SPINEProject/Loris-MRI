=head3 register_defaced_files($defaced_images)
Registers the defaced images using C<register_processed_data.pl>.
INPUT: hash with the defaced images storing their input FileID and scan type
=cut

sub register_defaced_files {
    my ($defaced_images) = @_;

    my $register_cmd = "register_processed_data.pl "
                       . " -profile $profile "
                       . " -sourcePipeline MINC_deface "
                       . " -tool 'uploadNeuroDB/bin/deface_minipipe.pl' "
                       . " -pipelineDate $today "
                       . " -coordinateSpace native "
                       . " -outputType defaced ";

    foreach my $file (keys $defaced_images) {
        my $input_fileID = $$defaced_images{$file}{InputFileID};
        my $scan_type    = $$defaced_images{$file}{Scan_type} . "-defaced";

        # verify that the scan type exists in mri_scan_type, if not create it
        create_defaced_scan_type($scan_type);

        # append file, scan type, sourceFileID & inputFileIDs to the command
        $register_cmd .= " -inputFileIDs $input_fileID "
                         . " -sourceFileID $input_fileID"
                         . " -scanType $scan_type "
                         . " -file $file";

        # register the scan in the DB
        my $exit_code = system($register_cmd);
        if ($exit_code != 0) {
            print "\nAn error occurred when running register_processed_data.pl."
                  . " Error Code was: " . $exit_code >> 8 . "Exiting now\n\n";
            exit $NeuroDB::ExitCodes::PROGRAM_EXECUTION_FAILURE;
        }
    }
}


=pod
