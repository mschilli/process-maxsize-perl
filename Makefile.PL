######################################################################
# Makefile.PL for Process::MaxSize
# 2006, Mike Schilli <mschilli@yahoo-inc.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Process::MaxSize',
    'VERSION_FROM' => 'MaxSize.pm', # finds $VERSION
    'PREREQ_PM'    => {
        "Log::Log4perl" => 1.0,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MaxSize.pm',
       AUTHOR     => 'Mike Schilli <mschilli@yahoo-inc.com>') : ()),
);
