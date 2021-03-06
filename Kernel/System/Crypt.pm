# --
# Kernel/System/Crypt.pm - the main crypt module
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: Crypt.pm,v 1.25 2012-11-20 15:33:16 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Crypt;

use strict;
use warnings;

use Kernel::System::FileTemp;
use Kernel::System::Time;

use vars qw($VERSION @ISA);
$VERSION = qw($Revision: 1.25 $) [1];

=head1 NAME

Kernel::System::Crypt - the crypt module

=head1 SYNOPSIS

All functions to encrypt/decrypt/sign and verify emails.
For backend module info see Kernel::System::Crypt::PGP and
Kernel::System::Crypt::SMIME.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create new object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::Crypt;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $CryptObject = Kernel::System::Crypt->new(
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        EncodeObject => $EncodeObject,
        CryptType    => 'PGP',   # PGP or SMIME
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = $Param{Debug} || 0;

    # get needed objects
    for (qw( ConfigObject EncodeObject LogObject MainObject DBObject CryptType )) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    # check if module is enabled
    return if !$Self->{ConfigObject}->Get( $Param{CryptType} );

    # create file template object
    $Self->{FileTempObject} = Kernel::System::FileTemp->new( %{$Self} );

    # load generator crypt module
    $Self->{GenericModule} = "Kernel::System::Crypt::$Param{CryptType}";
    return if !$Self->{MainObject}->Require( $Self->{GenericModule} );

    # time object
    $Self->{TimeObject} = Kernel::System::Time->new( %{$Self} );

    # add generator crypt functions
    @ISA = ("$Self->{GenericModule}");

    # call init()
    $Self->_Init();

    # check working env
    return if $Self->Check();

    return $Self;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.25 $ $Date: 2012-11-20 15:33:16 $

=cut
