package WebGUI::Asset::Wobject::TweetGrabber;

$VERSION = "0.0.1";

#-------------------------------------------------------------------
# Copyright _lsr 
#-------------------------------------------------------------------
#                                               shanebyron@gmail.com
#-------------------------------------------------------------------

use strict;
use Tie::IxHash;
use WebGUI::International;
use WebGUI::Utility;
use Net::Twitter::Lite;
use base 'WebGUI::AssetAspect::Installable', 'WebGUI::Asset::Wobject';

=head1 NAME 

Package WebGUI::Asset::Wobject::TweetGrabber
 
=head1 DESCRIPTION
 
Wobject for searching twitter status updates for a string


#-------------------------------------------------------------------

=head2 definition ( )

defines wobject properties for New Wobject instances. 

=cut

sub definition {
    my $class      = shift;
    my $session    = shift;
    my $definition = shift;
#    my $i18n       = WebGUI::International->new( $session, 'Asset_NewWobject' );
    tie my %properties, 'Tie::IxHash', (
        templateId => {

            fieldType => "template",
            defaultValue => 'TweetGrabber00001',
            tab          => "display",
            noFormPost => 0,
            namespace => "TweetGrabber",
            hoverHelp => "Choose a template for your TweetGrabber Wobject",
            label => "TweetGrabber Template",
        },
        tweetString=>{
					    tab=>"properties",
					    label=>"Tweet String",
					    hoverHelp=>"Enter a description to TweetSearch",
					    uiLevel=>3,
                        fieldType=>'text',
                        defaultValue=>'',
					    filter=>'fixUrl',
                    }        
    );
    push @{$definition}, {
        assetName         => 'TweetGrabber',
        icon              => 'article.gif',
        autoGenerateForms => 1,
        tableName         => 'TweetGrabber',
        className         => 'WebGUI::Asset::Wobject::TweetGrabber',
        properties        => \%properties
        };
    return $class->SUPER::definition( $session, $definition );
} ## end sub definition

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();
    my $template = WebGUI::Asset::Template->new( $self->session, $self->get("templateId") );
    $template->prepare($self->getMetaDataAsTemplateVariables);
    $self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------

=head2 install ( session )

Install the asset. C<session> is a WebGUI::Session object from the site to
install the asset into

To install this asset, best use WGD.

something like...
$ wgd util /data/WebGUI/sbin/installClass.pl WebGUI::Asset::Wobject::TweetGrabber --configFile=dev.localhost.localdomain

=cut

sub install {
    my $class   = shift;
    my $session = shift;

    ### Install the first member of the definition
    my $definition = $class->definition($session);
    my $installDef = shift @{$definition};

    # Make the table according to WebGUI::Form::Control's databaseFieldType
    my $sql
        = q{CREATE TABLE `}
        . $installDef->{tableName} . q{` ( }
        . q{`assetId` CHAR(22) BINARY NOT NULL, }
        . q{`revisionDate` BIGINT NOT NULL, };
    for my $column ( keys %{ $installDef->{properties} } ) {
        my $control = WebGUI::Form::DynamicField->new( $session, %{ $installDef->{properties}->{$column} } );
        $sql .= q{`} . $column . q{` } . $control->getDatabaseFieldType . q{, };

    }
    $sql .= q{ PRIMARY KEY ( assetId, revisionDate ) ) };

    $session->db->write($sql);

    
    my $import = WebGUI::Asset->getImportNode($session);
    $import->addChild({
        className=>"WebGUI::Asset::Template",
        template=>q|
                
<!--/ initiate admin controls -->

<tmpl_if session.var.adminOn>
	<tmpl_var controls>
</tmpl_if>

<!--/ initiate user form -->

<form action="#" method=GET>
<label>Something to tweet about:</label>
<input type='text' name='tweetTweet' />
<input type='submit' value='Submit'>
</form>

<!--/ if page loads from form input -->

<tmpl_if twote>
<p>You have searched for "<tmpl_var twote>":</p>
</tmpl_if twote>

<!--/ initiate list of tweets -->

<tmpl_if tweet>
    <tmpl_loop tweet>
        <br />A Twitter post from <tmpl_var tweetUsername>:
        <p><a href="http://twitter.com/<tmpl_var tweetUsername>"><img src="<tmpl_var tweetUserPic>"></a>
        <br /><tmpl_var tweetText>
        <br />on <tmpl_var tweetDate> 
        </p>
    </tmpl_loop tweet>
    
<!--/ unless there aren't any -->

<tmpl_else>
    <p>Sorry, couldn't find any tweets.</p>
</tmpl_if tweet>
        |,
        ownerUserId=>'3',
        groupIdView=>'7',
        groupIdEdit=>'12',
        title=>"TweetGrabber",
        menuTitle=>"TweetGrabber",
        url=>"templates/TweetGrabber",
        namespace=>"TweetGrabber"
    },'TweetGrabber00001');

    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name=>"Install TweetGrabber Wobject Template"});
    $versionTag->commit;
    $session->var->end;
    print "Installed Template.\n";

    # Write to the configuration
    $session->config->addToHash( "assets", $installDef->{className}, { category => "utilities" } );

    $session->close;


    return;
}
#
#----------------------------------------------------------------------------

=head2 uninstall ( session ) 

Unnstall the asset. C<session> is a WebGUI::Session object from the site to
uninstall the asset from.

To uninstall this asset, best use WGD.

something like...
$ wgd util /data/WebGUI/sbin/installClass.pl --remove WebGUI::Asset::Wobject::TweetGrabber --configFile=dev.localhost.localdomain

=cut

sub uninstall {
    my $class   = shift;
    my $session = shift;

    ### Uninstall the first member of the definition
    my $definition = $class->definition($session);
    my $installDef = shift @{$definition};

    ### Remove all assets contained in the table
    my $sth = $session->db->read("SELECT assetId FROM `$installDef->{tableName}`");
    while ( my ($assetId) = $sth->array ) {
        my $asset = WebGUI::Asset->newByDynamicClass( $session, $assetId );
        $asset->purge;
    }

    # Delete templates
    my $rs = $session->db->read("select distinct(assetId) from template where namespace='TweetGrabber'");
    while (my ($id) = $rs->array) {
        my $asset = WebGUI::Asset->new($session, $id, "WebGUI::Asset::Template");
        $asset->purge if defined $asset;

    }
    # Drop the table
    my $sql = q{DROP TABLE `} . $installDef->{tableName} . q{`};

    $session->db->write($sql);
    $session->config->deleteFromHash( "assets", $installDef->{className} );

    return;
} ## end sub uninstall


#-------------------------------------------------------------------


=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
    my $self    = shift;
    my $session = $self->session;
    # This automatically creates template variables for all of your wobject's properties.
    my $var = $self->get;
    # If no query has been passed in by the user, it defaults to what the admins enter in the Properties page
    my $twitter_query = $session->form->process('tweetTweet') || $self->get('tweetString');
    # Use the Twitter module to search
    my $search = Net::Twitter::Lite->new();
    my $output = $search->search($twitter_query);
    my $results = $output->{results};
    # Create template variables
	my @tweets;	
	foreach my $tweet ( @$results ) {		
		push ( @tweets, {
			tweetId			=> $tweet->{ id			},
			tweetDate		=> $tweet->{ created_at	        },
			tweetSource		=> $tweet->{ source		},
			tweetText		=> $tweet->{ text		},
			tweetUsername		=> $tweet->{ from_user		},
			tweetUserPic         	=> $tweet->{ profile_image_url  },
		} );
	}
    # return the array of tweets
    $var->{tweet} = \@tweets;
    # return the string we're tweeting about
    $var->{twote} = $session->form->process('tweetTweet');
    # spit it out
    return $self->processTemplate( $var, undef, $self->{_viewTemplate} );
  
}


1;
