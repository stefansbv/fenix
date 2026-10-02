package App::Fenix::Tk::App::Demo::Customers;

# ABSTRACT: The App::Demo::Customers screen

use Moo;

extends 'App::Fenix::Tk::Screen';

sub run_screen {
    my ( $self, $rec ) = @_;

    $self->_init($rec);                      # initilalization

    my $top = $self->top;                    # or use $self->top directly

    my $f1d = 120;    # distance from left

    #-- Frame1 - Customer

    my $frame1 = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Customer',
        -labelside  => 'acrosstop',
    )->grid(
        -row    => 0,
        -column => 0,
        -ipadx  => 5,
        -ipady  => 5,
        -sticky => 'nsew',
    );

    #- Customername (customername)

    my $lcustomername = $frame1->Label(
        -text => 'Customer',
    )->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecustomername = $frame1->MEntry(
        -width    => 35,
    )->form(
        -top  => [ '&', $lcustomername, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ Customernumber

    my $ecustomernumber = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&',            $lcustomername, 0 ],
        -left => [ $ecustomername, 5 ],
    );

    #- Contactlastname (contactlastname)

    my $lcontactlastname = $frame1->Label(
        -text => 'Last name',
    )->form(
        -top  => [ $lcustomername, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $econtactlastname = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $lcontactlastname, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Contactfirstname (contactfirstname)

    my $lcontactfirstname = $frame1->Label(
        -text => 'First name',
    )->form(
        -top  => [ $lcontactlastname, 0 ],
        -left => [ %0,                0 ],
        -padx => 5,
        -pady => 5,
    );

    my $econtactfirstname = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $lcontactfirstname, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Phone (phone)

    my $lphone = $frame1->Label(
        -text => 'Phone',
    )->form(
        -top  => [ $lcontactfirstname, 0 ],
        -left => [ %0,                 0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ephone = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $lphone, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Addressline1 (addressline1)

    my $laddressline1 = $frame1->Label(
        -text => 'Address line1',
    )->form(
        -top  => [ $lphone, 0 ],
        -left => [ %0,      0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eaddressline1 = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $laddressline1, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Addressline2 (addressline2)

    my $laddressline2 = $frame1->Label(
        -text => 'Address line2',
    )->form(
        -top  => [ $laddressline1, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $eaddressline2 = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $laddressline2, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- City (city)

    my $lcity = $frame1->Label(
        -text => 'City',
    )->form(
        -top  => [ $laddressline2, 0 ],
        -left => [ %0,             0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecity = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $lcity, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- State (state)

    my $lstate = $frame1->Label(
        -text => 'State',
    )->form(
        -top  => [ $lcity, 0 ],
        -left => [ %0,     0 ],
        -padx => 5,
        -pady => 5,
    );

    my $estate = $frame1->MEntry(
        -width => 42,
    )->form(
        -top  => [ '&', $lstate, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Countryname (countryname)

    my $lcountryname = $frame1->Label(
        -text => 'Country',
    )->form(
        -top  => [ $lstate, 0 ],
        -left => [ %0,      0 ],
        -padx => 5,
        -pady => 5,
    );

    my $ecountryname = $frame1->MEntry(
        -width => 35,
    )->form(
        -top  => [ '&', $lcountryname, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ Countrycode
    my $ecountrycode = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&',           $lcountryname, 0 ],
        -left => [ $ecountryname, 5 ],
    );

    #- Salesrepemployee (salesrepemployee)

    my $lsalesrepemployee = $frame1->Label(
        -text => 'Sales repres.',
    )->form(
        -top  => [ $lcountryname, 0 ],
        -padx => 5,
        -pady => 5,
        -left => [ %0,            0 ],
    );

    my $esalesrepemployee = $frame1->MEntry(
        -width => 35,
    )->form(
        -top  => [ '&', $lsalesrepemployee, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ Eemployeenumber

    my $eemployeenumber = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&',                $lsalesrepemployee, 0 ],
        -left => [ $esalesrepemployee, 5 ],
    );

    #- Creditlimit (creditlimit)

    my $lcreditlimit = $frame1->Label(
        -text => 'Credit limit',
    )->form(
        -top  => [ $lsalesrepemployee, 0 ],
        -left => [ %0,                 0 ],
        -padx => 5,
    );

    my $ecreditlimit = $frame1->MEntry(
        -width    => 10,
        -justify  => 'right',
    )->form(
        -top  => [ '&', $lcreditlimit, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Postalcode

    my $epostalcode = $frame1->MEntry(
        -width => 15,
    )->form(
        -top   => [ '&',  $lcreditlimit, 0 ],
        -right => [ %100, -5 ],
    );

    my $lpostalcode = $frame1->Label(
        -text => 'Postal code',
        -padx => 5,
    )->form(
        -top   => [ '&',          $lcreditlimit, 0 ],
        -right => [ $epostalcode, -20 ],
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'customers.conf'
    $self->{controls} = {
        customername     => [ 'e', undef, $ecustomername ],
        customernumber   => [ 'e', undef, $ecustomernumber ],
        contactlastname  => [ 'e', undef, $econtactlastname ],
        contactfirstname => [ 'e', undef, $econtactfirstname ],
        phone            => [ 'e', undef, $ephone ],
        addressline1     => [ 'e', undef, $eaddressline1 ],
        addressline2     => [ 'e', undef, $eaddressline2 ],
        city             => [ 'e', undef, $ecity ],
        state            => [ 'e', undef, $estate ],
        countryname      => [ 'e', undef, $ecountryname ],
        countrycode      => [ 'e', undef, $ecountrycode ],
        salesrepemployee => [ 'e', undef, $esalesrepemployee ],
        employeenumber   => [ 'e', undef, $eemployeenumber ],
        creditlimit      => [ 'e', undef, $ecreditlimit ],
        postalcode       => [ 'e', undef, $epostalcode ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{rq_controls} = {
        customername     => [ 0, '  Customer name' ],
        contactlastname  => [ 1, '  Contact last name' ],
        contactfirstname => [ 2, '  Contact first name' ],
        phone            => [ 3, '  Phone' ],
        addressline1     => [ 4, '  Address line 1' ],
        city             => [ 5, '  City' ],
        countrycode      => [ 6, '  Country' ],
    };

    return;
}

1;

=head1 SYNOPSIS

    require App::Fenix::App::Demo::Customers;

    my $scr = App::Fenix::App::Demo::Customers->new;

    $scr->run_screen($args);

=head2 run_screen

The screen layout

=cut
