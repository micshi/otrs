# --
# Kernel/System/Ticket/Event/TriggerEscalationStopEvents.pm - trigger escalation stop events
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: TriggerEscalationStopEvents.pm,v 1.5 2012-11-20 16:01:33 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::TriggerEscalationStopEvents;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.5 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(ConfigObject TicketObject LogObject UserObject CustomerUserObject TimeObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Event UserID Config)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Needed!" );
            return;
        }
    }
    for my $Needed (qw(OldTicketData TicketID)) {
        if ( !$Param{Data}->{$Needed} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Needed in Data!" );
            return;
        }
    }

    # get the current escalation status
    my %Ticket = $Self->{TicketObject}->TicketGet(
        TicketID      => $Param{Data}->{TicketID},
        UserID        => $Param{UserID},
        DynamicFields => 0,
    );

    # compare old and the current escalation status
    my %Attr2Event = (
        FirstResponseTimeEscalation => 'EscalationResponseTimeStop',
        UpdateTimeEscalation        => 'EscalationUpdateTimeStop',
        SolutionTimeEscalation      => 'EscalationSolutionTimeStop',
    );
    while ( my ( $Attr, $Event ) = each %Attr2Event ) {
        if ( $Param{Data}->{OldTicketData}->{$Attr} && !$Ticket{$Attr} ) {

            # trigger the event
            $Self->{TicketObject}->EventHandler(
                Event  => $Event,
                UserID => $Param{UserID},
                Data   => {
                    TicketID      => $Param{Data}->{TicketID},
                    OldTicketData => $Param{Data}->{OldTicketData},
                },
            );

            # log the triggered event in the history
            $Self->{TicketObject}->HistoryAdd(
                TicketID     => $Param{Data}->{TicketID},
                HistoryType  => $Event,
                Name         => "%%$Event%%triggered",
                CreateUserID => $Param{UserID},
            );
        }
    }

    return 1;
}

1;
