# Copyright (c) 2013 Zmanda, Inc.  All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# Contact information: Zmanda Inc., 465 S. Mathilda Ave., Suite 300
# Sunnyvale, CA 94085, USA, or: http://www.zmanda.com

package Amanda::Rest::Runs;
use strict;
use warnings;

use Amanda::Config qw( :init :getconf config_dir_relative );
use Amanda::Amdump;
use Amanda::Amflush;
use Amanda::CheckDump;
use Amanda::FetchDump;
use Amanda::Cleanup;
use Amanda::Vault;
use Amanda::Rest::Configs;
use Amanda::Process;
use Symbol;
use Data::Dumper;

use vars qw(@ISA);

=head1 NAME

Amanda::Rest::Runs -- Rest interface to Amanda::Amdump, Amanda::Amflush, Amanda::Vault

=head1 INTERFACE

=over

=item Run amdump

 request:
  POST localhost:5000/amanda/v1.0/configs/:CONFIG/runs/amdump
    query arguments:
        host=HOST
        disk=DISK               #repeatable
        hostdisk=HOST|DISK      #repeatable
        no_taper=0|1
        from_client=0|1

 reply:
  HTTP status: 202 Accepted
  [
     {
        "timestamp" : "20140205112550",
        "code" : "2000003",
        "message" : "The timestamp is '20140205112550'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amdump.pm",
        "source_line" : "96"
     },
     {
        "amdump_log" : "/var/log/amanda/test/amdump.20140205112550",
        "code" : "2000001",
        "message" : "The amdump log file is '/var/log/amanda/test/amdump.20140205112550'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amdump.pm",
        "source_line" : "102"
     },
     {
        "code" : "2000000",
        "message" : "The trace log file is '/var/log/amanda/test/log.20140205112550.0'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amdump.pm",
        "source_line" : "108",
        "trace_log" : "/var/log/amanda/test/log.20140205112550.0"
     },
     {
        "code" : "2000002",
        "message" : "Running a dump",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
        "source_line" : "269"
     }
  ]

=item Run amflush

 request:
  POST localhost:5000/amanda/v1.0/configs/:CONFIG/runs/amflush
    query arguments:
        host=HOST
        disk=DISK               #repeatable
        hostdisk=HOST|DISK      #repeatable
	datestamps=DATESTAMP    #repeatable

 reply:
  HTTP status: 202 Accepted
  [
     {
        "timestamp" : "20140205120327",
        "code" : "2200006",
        "message" : "The timestamp is '20140205120327'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amflush.pm",
        "source_line" : "101"
     },
     {
        "amdump_log" : "/var/log/amanda/test/amdump.20140205120327",
        "code" : "2200001",
        "message" : "The amdump log file is '/var/log/amanda/test/amdump.20140205120327'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amflush.pm",
        "source_line" : "107"
     },
     {
        "code" : "2200000",
        "message" : "The trace log file is '/var/log/amanda/test/log.20140205120327.0'",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Amflush.pm",
        "source_line" : "113",
        "trace_log" : "/var/log/amanda/test/log.20140205120327.0"
     },
     {
        "code" : "2200005",
        "message" : "Running a flush",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
        "source_line" : "421"
     }
  ]

=item Run amvault

 request:
  POST localhost:5000/amanda/v1.0/configs/:CONFIG/runs/amvault
    query arguments:
        host=HOST
        disk=DISK               #repeatable
        hostdisk=HOST|DISK      #repeatable
        quiet=0|1
        fulls_only=0|1
        latest_fulls=0|1
        incrs_only=0|1
        opt_export=0|1
        opt_dry_run=0|1
        src_write_timestamp=TIMESTAMP
        dst_write_timestamp=TIMESTAMP

 reply:
  HTTP status: 202 Accepted

=item Run amcheckdump

 request:
  POST localhost:5000/amanda/v1.0/configs/:CONFIG/runs/checkdump
    query argument:
        timestamp=TIMESTAMP

 reply:
  HTTP status 202 Accepted
  [
     {
        "code" : "2700018",
        "message" : "Running a CheckDump",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
        "source_line" : "415"
     },
     {
        "code" : "2700020",
        "message" : "The message filename is 'checkdump.3545'",
        "message_filename" : "checkdump.3545",
        "severity" : "2",
        "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
        "source_line" : "420"
     }
  ]

=item Get messages for amcheckdump

 request:
  GET localhost:5000/amanda/v1.0/configs/:CONFIG/runs/messages
    query argument:
        message_filename=MESAGE_FILENAME

 reply:
  HTTP status 200 Ok
  [
     {
        "code" : 2700001,
        "labels" : [
           {
              "available" : 0,
              "label" : "test-ORG-AG-vtapes-005",
              "storage" : "my_vtapes"
           }
        ],
        "message" : "You will need the following volume: test-ORG-AG-vtapes-005",
        "severity" : 16,
        "source_filename" : "/usr/lib/amanda/perl/Amanda/CheckDump.pm",
        "source_line" : "367"
     },
     {
        "code" : 2700005,
        "diskname" : "/bootAMGTAR",
        "dump_timestamp" : "20140516130638",
        "hostname" : "localhost.localdomain",
        "level" : 1,
        "message" : "Validating image localhost.localdomain:/bootAMGTAR dumped 20140516130638 level 1",
        "nparts" : 1,
        "severity" : 16,
        "source_filename" : "/usr/lib/amanda/perl/Amanda/CheckDump.pm",
        "source_line" : "402"
     },
     {
        "code" : 2700003,
        "filenum" : 1,
        "label" : "test-ORG-AG-vtapes-005",
        "message" : "Reading volume test-ORG-AG-vtapes-005 file 1",
        "severity" : 16,
        "source_filename" : "/usr/lib/amanda/perl/Amanda/CheckDump.pm",
        "source_line" : "175"
     },
     {
        "code" : 2700006,
        "message" : "All images successfully validated",
        "severity" : 16,
        "source_filename" : "/usr/lib/amanda/perl/Amanda/CheckDump.pm",
        "source_line" : "695"
     }
  ]

=item Run amfetchdump --extract

 request:
  POST localhost:5000/amanda/v1.0/configs/:CONFIG/runs/fetchdump
    query argument:
      host=HOST
      disk=DISK
      timestamp=TIMESTAMP
      level=LEVEL
      write_timestamp=WRITE_TIMESTAMP
      directory=/PATH/WHERE/TO/EXTRACT

      The application_property setting can only be set in the body
    of the POST request, the Content-Type header must be set to
    'application/json'.

    POST header:
	Content-Type: application/json
    POST body (example):
      { "application_property":{ "esxpass":"/etc/amanda/esxpass"}}

 reply:
  HTTP status 202 Accepted
  [
   {
      "code" : "3300057",
      "message" : "Running a Fetchdump",
      "severity" : "2",
      "source_filename" : "/amanda/h1/linux/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "734"
   },
   {
      "code" : "3300059",
      "message" : "The message filename is 'fetchdump.27363'",
      "message_filename" : "fetchdump.27363",
      "severity" : "2",
      "source_filename" : "/amanda/h1/linux/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "739"
   }
  ]

=item Get messages for amfetchdump

 request:
  GET localhost:5000/amanda/v1.0/configs/:CONFIG/runs/messages
    query argument:
        message_filename=MESAGE_FILENAME

 reply:
  HTTP status 200 Ok
  [
   {
      "code" : 3300002,
      "message" : "1 volume(s) needed for restoration\nThe following volumes are needed: Xtest-ORG-AG-vtapes-004\n",
      "needed_holding" : [],
      "needed_labels" : [
         {
            "available" : 0,
            "label" : "Xtest-ORG-AG-vtapes-004",
            "storage" : "my_vtapes"
         }
      ],
      "severity" : 16,
      "source_filename" : "/usr/lib/amanda/perl/Amanda/FetchDump.pm",
      "source_line" : "689"
   },
   {
      "code" : 3300012,
      "message" : "READ SIZE: 85504 kb",
      "severity" : 16,
      "size" : 87556096,
      "source_filename" : "/usr/lib/amanda/perl/Amanda/FetchDump.pm",
      "source_line" : "1347"
   },
   {
      "code" : 3300013,
      "message" :
      "severity" : 16,
      "source_filename" : "/usr/lib/amanda/perl/Amanda/FetchDump.pm",
      "source_line" : "1357",
      "application_stdout: [ ... ]
   }
  ]

=item Get a list of all operations

 request:
  GET localhost:5000/amanda/v1.0/configs/:CONFIG/runs
    optional query arguments:
	status=STATUS
	run_type=$RUN_TYPE

 reply:
  HTTP status 200 Ok
  [
   {
      "amdump_log" : "/etc/amanda/TESTCONF/logs/amdump.20140527122705",
      "code" : "2000004",
      "message" : "one run",
      "run_type" : "amdump",
      "severity" : "16",
      "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "985",
      "status" : "aborted",
      "timestamp" : "20140527122705",
      "trace_log" : "/etc/amanda/TESTCONF/logst/log.20140527122705.0"
   },
   {
      "amdump_log" : "/etc/amanda/TESTCONF/logs/amdump.20140702163539",
      "code" : "2000004",
      "message" : "one run",
      "run_type" : "amflush",
      "severity" : "16",
      "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "985",
      "status" : "aborted",
      "timestamp" : "20140702163539",
      "trace_log" : "/etc/amanda/TESTCONF/logs/log.20140702163539.0"
   },
   {
      "amdump_log" : "/etc/amanda/TESTCONF/logs/amdump.20140708100915",
      "code" : "2000004",
      "message" : "one run",
      "run_type" : "amvault",
      "severity" : "16",
      "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "985",
      "status" : "done",
      "timestamp" : "20140708100915",
      "trace_log" : "/etc/amanda/TESTCONF/logs/log.20140708100915.0"
   },
   {
      "code" : "2000004",
      "message" : "one run",
      "message_file" : "/etc/amanda/TESTCONF/logs/checkdump.20140922151405",
      "run_type" : "checkdump",
      "severity" : "16",
      "source_filename" : "/usr/lib/amanda/perl/Amanda/Rest/Runs.pm",
      "source_line" : "995",
      "status" : "done",
      "timestamp" : "20140922151405",
      "trace_log" : "/etc/amanda/TESTCONF/logs/log.20140922151405.0"
   },


  ]

=item kill a run (amcleanup)

 request:
  DELETE localhost:5000/amanda/v1.0/configs/:CONFIG/runs
    query arguments:
        trace_log=LOG_FILE
        kill=0|1
        alive=0|1
        clean_holding=0|1

 reply:
  HTTP status: 200 Ok

=back

=cut

sub amdump {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    Amanda::Util::set_pname("amdump");
    my $user_msg = sub {
	my $msg = shift;
	push @result_messages, $msg;
    };

    if (defined($params{'host'})) {
	my @hostdisk;
	if (defined($params{'disk'})) {
	    if (ref($params{'disk'}) eq 'ARRAY') {
		foreach my $disk (@{$params{'disk'}}) {
		    push @hostdisk, $params{'host'}, $disk;
		}
	    } else {
		push @hostdisk, $params{'host'}, ${'disk'};
	    }
	} else {
	    push @hostdisk, $params{'host'};
	}
	$params{'hostdisk'} = \@hostdisk;
    }
    $params{'config'} = $params{'CONF'};
    $params{'exact_match'} = 1;
    my ($amdump, $messages) = Amanda::Amdump->new(%params, user_msg => $user_msg);
    push @result_messages, @{$messages};

    # fork the amdump process and detach
    my $pid = POSIX::fork();
    if ($pid == 0) {
	my $exit_code = $amdump->run(0);
	Amanda::Debug::debug("exiting with code $exit_code");
	exit($exit_code);
    }

    push @result_messages, Amanda::Amdump::Message->new(
	source_filename => __FILE__,
	source_line     => __LINE__,
	code         => 2000002,
	severity     => $Amanda::Message::SUCCESS);
    Dancer::status(202);

    return \@result_messages;
}

sub amvault {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    Amanda::Util::set_pname("amvault");
    my $user_msg = sub {
	my $msg = shift;
	push @result_messages, $msg;
    };

    if (defined($params{'host'})) {
	my @hostdisk;
	if (defined($params{'disk'})) {
	    if (ref($params{'disk'}) eq 'ARRAY') {
		foreach my $disk (@{$params{'disk'}}) {
		    push @hostdisk, $params{'host'}, $disk;
		}
	    } else {
		push @hostdisk, $params{'host'}, ${'disk'};
	    }
	} else {
	    push @hostdisk, $params{'host'};
	}
	$params{'hostdisk'} = \@hostdisk;
    }
    $params{'config'} = $params{'CONF'};
    $params{'exact_match'} = $params{'CONF'};
    my ($vault, $messages) = Amanda::Vault->new(%params, user_msg => $user_msg);
    push @result_messages, @{$messages};

    # fork the vault process and detach
    my $pid = POSIX::fork();
    if ($pid == 0) {
	my $exit_code = $vault->run(0);
	Amanda::Debug::debug("exiting with code $exit_code");
	exit($exit_code);
    }

    push @result_messages, Amanda::Vault::Message->new(
	source_filename => __FILE__,
	source_line     => __LINE__,
	code         => 2400003,
	severity     => $Amanda::Message::SUCCESS);
    Dancer::status(202);

    return \@result_messages;
}

sub amflush {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    my $diskfile = config_dir_relative(getconf($CNF_DISKFILE));
    Amanda::Disklist::unload_disklist();
    my $cfgerr_level = Amanda::Disklist::read_disklist('filename' => $diskfile);
    if ($cfgerr_level >= $CFGERR_ERRORS) {
	return Amanda::Disklist::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => 1400006,
			severity     => $Amanda::Message::ERROR,
			diskfile     => $diskfile,
			cfgerr_level => $cfgerr_level);
    }

    Amanda::Util::set_pname("amflush");
    my $user_msg = sub {
	my $msg = shift;
	push @result_messages, $msg;
    };

    if (defined($params{'host'})) {
	my @hostdisk;
	if (defined($params{'disk'})) {
	    if (ref($params{'disk'}) eq 'ARRAY') {
		foreach my $disk (@{$params{'disk'}}) {
		    push @hostdisk, $params{'host'}, $disk;
		}
	    } else {
		push @hostdisk, $params{'host'}, ${'disk'};
	    }
	} else {
	    push @hostdisk, $params{'host'};
	}
	$params{'hostdisk'} = \@hostdisk;
    }
    $params{'config'} = $params{'CONF'};
    $params{'exact_match'} = 1;

    Amanda::Disklist::match_disklist(
        user_msg => $user_msg,
        exact_match => $params{'exact_match'},
        args        => $params{'hostdisk'});

    my ($amflush, $messages) = Amanda::Amflush->new(%params, user_msg => $user_msg);
    push @result_messages, @{$messages};
    open STDERR, ">>&", $amflush->{'amdump_log'} || die("stdout: $!");

    my $code;
    my @ts = Amanda::Holding::get_all_datestamps();
    my @datestamps;
    if (defined $params{'datestamps'} and @{$params{'datestamps'}}) {
	foreach my $datestamp (@{$params{'datestamps'}}) {
	    my $matched = 0;
	    foreach my $ts (@ts) {
		if (Amanda::Util::match_datestamp($datestamp, $ts)) {
		    push @datestamps, $ts;
		    $matched = 1;
		    last;
		}
	    }
	    if (!$matched) {
		push @result_messages, Amanda::Amflush::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => 2200002,
			severity     => $Amanda::Message::WARNING,
			datestamp    => $datestamp);
	    }
	}
	$code = 2200003;
    } else {
	@datestamps = @ts;
	$code = 2200004;
    }
    if (!@datestamps) {
	push @result_messages, Amanda::Amflush::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => $code,
			severity     => $Amanda::Message::WARNING);
	return \@result_messages;
    }

    # fork the amdump process and detach
    my $pid = POSIX::fork();
    if ($pid == 0) {
	my $to_flushs = $amflush->get_flush(datestamps => \@datestamps);
	my $exit_code = $amflush->run(0, $to_flushs);
	Amanda::Debug::debug("exiting with code $exit_code");
	exit($exit_code);
    }
    push @result_messages, Amanda::Amflush::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => 2200005,
			severity     => $Amanda::Message::SUCCESS);
    Dancer::status(202);

    return \@result_messages;
}

sub checkdump {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    my $diskfile = config_dir_relative(getconf($CNF_DISKFILE));
    Amanda::Disklist::unload_disklist();
    my $cfgerr_level = Amanda::Disklist::read_disklist('filename' => $diskfile);
    if ($cfgerr_level >= $CFGERR_ERRORS) {
	return Amanda::Disklist::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => 1400006,
			severity     => $Amanda::Message::ERROR,
			diskfile     => $diskfile,
			cfgerr_level => $cfgerr_level);
    }

    Amanda::Util::set_pname("checkdump");

    my ($checkdump, $messages) = Amanda::CheckDump->new(%params);
    push @result_messages, @{$messages};

    if (!$checkdump) {
	return \@result_messages;
    }

    my $exit_status = 0;
    my $exit_cb = sub {
	($exit_status) = @_;
	Amanda::MainLoop::quit();
    };

    my $pid = POSIX::fork();
    if ($pid == 0) {
	Amanda::MainLoop::call_later(sub { $checkdump->run($exit_cb) });
	Amanda::MainLoop::run();
	exit;
    } elsif ($pid > 0) {
	push @result_messages, Amanda::CheckDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 2700018,
		severity         => $Amanda::Message::SUCCESS);
	push @result_messages, Amanda::CheckDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 2700020,
		severity         => $Amanda::Message::INFO,
		message_filename => $checkdump->{'checkdump_log_filename'});
    } else {
	push @result_messages, Amanda::CheckDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 2700019,
		severity         => $Amanda::Message::ERROR);
    }
    Dancer::status(202);

    return \@result_messages;
}

package Amanda::Rest::Runs::FetchFeedback;
use base 'Amanda::Recovery::Clerk::Feedback';

sub new {
    my $class = shift;

    my $self = bless {
    }, $class;

    return $self;
}

sub set_feedback {
    my $self = shift;
    my %params = @_;

    $self->{'chg'} = $params{'chg'} if exists $params{'chg'};
    $self->{'dev_name'} = $params{'dev_name'} if exists $params{'dev_name'};

    return $self;
}

sub clerk_notif_part {
    my $self = shift;
    my ($label, $filenum, $header) = @_;

    $self->user_message(Amanda::FetchDump::Message->new(
		source_filename	=> __FILE__,
		source_line	=> __LINE__,
		code		=> 3300003,
		severity        => $Amanda::Message::INFO,
		label		=> $label,
		filenum		=> $filenum,
		header_summary	=> $header->summary()));
}

sub clerk_notif_holding {
    my $self = shift;
    my ($filename, $header) = @_;

    $self->user_message(Amanda::FetchDump::Message->new(
		source_filename	=> __FILE__,
		source_line	=> __LINE__,
		code		=> 3300004,
		severity        => $Amanda::Message::INFO,
		holding_file	=> $filename,
		header_summary	=> $header->summary()));
}

package Amanda::Rest::Runs;

sub fetchdump {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    my $diskfile = config_dir_relative(getconf($CNF_DISKFILE));
    Amanda::Disklist::unload_disklist();
    my $cfgerr_level = Amanda::Disklist::read_disklist('filename' => $diskfile);
    if ($cfgerr_level >= $CFGERR_ERRORS) {
	return Amanda::Disklist::Message->new(
			source_filename => __FILE__,
			source_line     => __LINE__,
			code         => 1400006,
			severity     => $Amanda::Message::ERROR,
			diskfile     => $diskfile,
			cfgerr_level => $cfgerr_level);
    }

    Amanda::Util::set_pname("fetchdump");

    my ($fetchdump, $messages) = Amanda::FetchDump->new(%params);
    push @result_messages, @{$messages};

    if (!$fetchdump) {
	return \@result_messages;
    }

    my $exit_status = 0;

    my $pid = POSIX::fork();
    if ($pid == 0) {

	my $spec = Amanda::Cmdline::dumpspec_t->new($params{'host'}, $params{'disk'}, $params{'timestamp'}, $params{'level'}, $params{'write_timestamp'});
	my @dumpspecs;
	push @dumpspecs, $spec;
	my $fetchfeedback = Amanda::Rest::Runs::FetchFeedback->new();
	my $finished_cb = sub { $exit_status = shift;
				$fetchdump->user_message(
				    Amanda::FetchDump::Message->new(
					source_filename	=> __FILE__,
					source_line	=> __LINE__,
					code		=> 3300060,
					severity	=> $exit_status == 0 ? $Amanda::Message::SUCCESS : $Amanda::Message::ERROR,
					exit_status	=> $exit_status));
				Amanda::MainLoop::quit(); };
	Amanda::MainLoop::call_later(sub { $fetchdump->restore(
                'application_property'  => $params{'application_property'},
#                'assume'                => $opt_assume,
#                'chdir'                 => $opt_chdir,
#                'client-decompress'     => $opt_client_decompress,
#                'client-decrypt'        => $opt_client_decrypt,
#                'compress'              => $opt_compress,
#                'compress-best'         => $opt_compress_best,
#                'data-path'             => $opt_data_path,
                'decompress'            => 1,
                'decrypt'               => 1,
                'device'                => $params{'device'},
                'directory'             => $params{'directory'},
                'dumpspecs'             => \@dumpspecs,
                'exact-match'           => 1,
                'extract'               => 1,
#                'header'                => $opt_header,
#                'header-fd'             => $opt_header_fd,
#                'header-file'           => $opt_header_file,
#                'init'                  => $opt_init,
#                'leave'                 => $opt_leave,
#                'no-reassembly'         => $opt_no_reassembly,
#                'pipe-fd'               => $opt_pipe ? 1 : undef,
                'restore'               => 1,
#                'server-decompress'     => 1,
#                'server-decrypt'        => 1,
                'finished_cb'           => $finished_cb,
#                'interactivity'         => $interactivity,
                'feedback'              => $fetchfeedback) });
	Amanda::MainLoop::run();
	exit;
    } elsif ($pid > 0) {
	push @result_messages, Amanda::FetchDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 3300057,
		severity         => $Amanda::Message::SUCCESS);
	push @result_messages, Amanda::FetchDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 3300059,
		message_filename => $fetchdump->{'fetchdump_log_filename'},
		severity         => $Amanda::Message::INFO);
    } else {
	push @result_messages, Amanda::FetchDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 3300058,
		severity         => $Amanda::Message::ERROR);
    }
    Dancer::status(202);

    return \@result_messages;
}

sub messages {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    if (!$params{'message_filename'}) {
	push @result_messages, Amanda::CheckDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 2700022,
		severity         => $Amanda::Message::ERROR);
	return \@result_messages;
    }
    my $message_path =  getconf($CNF_LOGDIR) . "/" . $params{'message_filename'};
    my $message_fh;
    if (!open ($message_fh, "<$message_path")) {
	push @result_messages, Amanda::CheckDump::Message->new(
		source_filename  => __FILE__,
		source_line      => __LINE__,
		code             => 2700023,
		severity         => $Amanda::Message::ERROR,
		message_filename => $params{'message_filename'},
		errno            => $!);
	return \@result_messages;
    }

    my $data;
    {
	local $/;
	$data = <$message_fh>;
    }

    my @MESSAGES;
    eval $data;
    return \@MESSAGES;
}

sub list {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    my $Amanda_process = Amanda::Process->new();
    $Amanda_process->load_ps_table();

    my $logdir = Amanda::Config::getconf($CNF_LOGDIR);
    foreach my $logfile (<$logdir/amdump.*>, <$logdir/fetchdump.*>, <$logdir/checkdump.*> ) {
	my $timestamp;
	if ($logfile =~ /amdump\.(.*)$/) {
	    $timestamp = $1;
	}
	if (!defined $timestamp) {
	    if ($logfile =~ /checkdump\.(.*)$/) {
		$timestamp = $1;
	    }
	}
	if (!defined $timestamp) {
	    if ($logfile =~ /fetchdump\.(.*)$/) {
		$timestamp = $1;
	    }
	}
	next if length($timestamp) != 14;
	my $run_type;
	my $pid;
	my $status = "running";
	my $tracefile = "$logdir/log.$timestamp.0";
	my $message_file;
	next if !-f $tracefile;

	open (TRACE, "<", $tracefile);
	while (my $line = <TRACE>) {
	    if ($line =~ /^INFO amdump amdump pid (\d*)$/) {
		$run_type = "amdump";
		$pid = $1;
	    } elsif ($line =~ /^INFO amflush amflush pid (\d*)$/) {
		$run_type = "amflush";
		$pid = $1;
	    } elsif ($line =~ /^INFO amvault amvault pid (\d*)$/) {
		$run_type = "amvault";
		$pid = $1;
	    } elsif ($line =~ /^INFO checkdump checkdump pid (\d*)$/) {
		$run_type = "checkdump";
		$pid = $1;
	    } elsif ($line =~ /^INFO fetchdump fetchdump pid (\d*)$/) {
		$run_type = "fetchdump";
		$pid = $1;
	    } elsif ($line =~ /^INFO .* message_file (.*)$/) {
		$message_file = $1;
	    }
	    if (defined $run_type and
		$line =~ /^INFO $run_type pid-done $pid/) {
		$status = "done";
	    }
	}
	if ($status eq "running" and $pid) {
	    $status = "aborted" if !$Amanda_process->process_alive($pid, $run_type);
	}
	if ((!defined($params{'status'}) or
	     $params{'status'} eq $status) and
	    (!defined($params{'run_type'}) or
	     $params{'run_type'} eq $run_type)) {
	    if ($run_type eq "amdump" or
		$run_type eq "amflush" or
		$run_type eq "amvault") {
		push @result_messages, Amanda::Amdump::Message->new(
			source_filename  => __FILE__,
			source_line      => __LINE__,
			code             => 2000004,
			severity         => $Amanda::Message::INFO,
			run_type         => $run_type,
			timestamp        => $timestamp,
			amdump_log       => $logfile,
			trace_log        => $tracefile,
			status           => $status);
	    } else {
		push @result_messages, Amanda::Amdump::Message->new(
			source_filename  => __FILE__,
			source_line      => __LINE__,
			code             => 2000004,
			severity         => $Amanda::Message::INFO,
			run_type         => $run_type,
			timestamp        => $timestamp,
			message_file     => $logfile,
			trace_log        => $tracefile,
			status           => $status);
	    }
	}
    }

    return \@result_messages;
}

sub kill {
    my %params = @_;
    Amanda::Util::set_pname("Amanda::Rest::Runs");
    my @result_messages = Amanda::Rest::Configs::config_init(@_);
    return \@result_messages if @result_messages;

    my $cleanup = Amanda::Cleanup->new(trace_log     => $params{'trace_log'},
				       kill          => $params{'kill'},
				       process_alive => $params{'alive'},
				       verbose       => $params{'verbose'},
				       clean_holding => $params{'clean_holding'});

    @result_messages = $cleanup->cleanup();

    return \@result_messages;
}

1;
