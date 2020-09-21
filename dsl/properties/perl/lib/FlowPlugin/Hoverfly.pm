package FlowPlugin::Hoverfly;
use strict;
use warnings;
use base qw/FlowPDF/;
use FlowPDF::Log;
use Hoverfly::REST;
use JSON;

# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName          => '@PLUGIN_KEY@',
        pluginVersion       => '@PLUGIN_VERSION@',
        configFields        => ['config'],
        configLocations     => ['ec_plugin_cfgs'],
        defaultConfigValues => {}
    };
}


# Auto-generated method for the connection check.
# Add your code into this method and it will be called when configuration is getting created.
# $self - reference to the plugin object
# $p - step parameters
# $sr - StepResult object
# Parameter: config
# Parameter: desc
# Parameter: endpoint

sub checkConnection {
    my ($self, $p, $sr) = @_;

    my $context = $self->getContext();
    my $configValues = $context->getConfigValues()->asHashref();
    logInfo("Config values are: ", $configValues);

    eval {
        # Use $configValues to check connection, e.g. perform some ping request
        # my $client = Client->new($configValues); $client->ping();
        my $password = $configValues->{password};
        if ($password ne 'secret') {
            my $h = $self->newHoverflyClient();
            my $mode = $h->get_mode();
        }
        1;
    } or do {
        my $err = $@;
        # Use this property to surface the connection error details in the CD server UI
        $sr->setOutcomeProperty("/myJob/configError", $err);
        $sr->apply();
        die $err;
    };
}

## === check connection ends ===

# Auto-generated method for the procedure Switch/Switch
# Add your code into this method and it will be called when step runs
# $self - reference to the plugin object
# $p - step parameters
# Parameter: config
# Parameter: hoverflyMode
# Parameter: hoverflyArgs

# $sr - StepResult object
sub switch {
    my ($self, $p, $sr) = @_;

    my $context = $self->getContext();
    logInfo("Current context is: ", $context->getRunContext());
    logInfo("Step parameters are: ", $p);

    my $configValues = $context->getConfigValues();
    logInfo("Config values are: ", $configValues);

    my $h = $self->newHoverflyClient();
    my $args = {};

    if ($p->{hoverflyArgs}) {
        $args = decode_json($p->{hoverflyArgs});
    }

    logInfo("Args: ", $args);
    my $newMode = $h->switch_mode($p->{hoverflyMode}, $args);
    # $sr->setJobStepOutcome('warning');
    # $sr->setJobSummary("This is a job summary.");
    $sr->setOutputParameter('Hoverfly Mode' => $newMode);
    $sr->setJobSummary("Hoverfly has been switched to '$newMode' mode");
}
# Auto-generated method for the procedure Export Simulation/Export Simulation
# Add your code into this method and it will be called when step runs
# $self - reference to the plugin object
# $p - step parameters
# Parameter: config
# Parameter: simulationFilePath

# $sr - StepResult object
sub exportSimulation {
    my ($self, $p, $sr) = @_;

    my $context = $self->getContext();
    my $h = $self->newHoverflyClient();

    my $simulation = $h->get_simulation();
    my $fp = $p->{simulationFilePath};

    if (!$p->{overwriteSimulation} && -e $fp) {
        $context->bailOut("File $fp is already exists");
    }
    open (my $fh, '>', $fp) or $context->bailOut("Can't open simulation file $fp for writing.");
    print $fh $simulation;
    close $fh;
    $sr->setOutputParameter('Simulation Content', $simulation);
    $sr->setJobSummary("Simulation has been exported");
}
# Auto-generated method for the procedure Import Simulation/Import Simulation
# Add your code into this method and it will be called when step runs
# $self - reference to the plugin object
# $p - step parameters
# Parameter: config
# Parameter: simulationFilePath

# $sr - StepResult object
sub importSimulation {
    my ($self, $p, $sr) = @_;

    my $context = $self->getContext();
    my $h = $self->newHoverflyClient();

    my $fp = $p->{simulationFilePath};

    if (!-e $fp) {
        $context->bailOut("File $fp does not exist. Can't import.");
    }

    open (my $fh, $fp);
    my $content = join('', <$fh>);
    close $fh;
    $h->set_simulation($content);
    $sr->setJobSummary("Simulation has been imported from $fp");
}

## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.


sub newHoverflyClient {
    my ($self) = @_;

    my $context = $self->getContext();
    my $configValues = $context->getConfigValues()->asHashref();

    my $url = $configValues->{endpoint};

    unless ($url) {
        logInfo("Using default hoverfly URL");
        return Hoverfly::REST->new();
    }

    if ($url =~ m|(https?)://(.*?):(.\d+)$|s) {
        logInfo "Proto: '$1', Host: '$2', Port: '$3'";
        return Hoverfly::REST->new({
            proto => $1,
            host  => $2,
            port  => $3
        });
    }
    else {
        $self->getContext()->bailOut("Wrong url format. Expected proto, host and port");
    }
}

1;

