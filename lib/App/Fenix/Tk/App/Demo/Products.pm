package App::Fenix::Tk::App::Demo::Products;

# ABSTRACT: The App::Fenix::App::Demo::Products screen

use Moo;

extends 'App::Fenix::Tk::Screen';

sub run_screen {
    my ( $self, $rec ) = @_;

    $self->_init($rec);                      # initilalization

    my $top = $self->top;                    # or use $self->top directly

    my $f1d = 100;    # distance from left

    #- Frame1 - Products

    my $frame1 = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Product',
        -labelside  => 'acrosstop',
    )->grid(
        -row    => 0,
        -column => 0,
        -ipadx  => 3,
        -ipady  => 3,
        -sticky => 'nsew',
    );

    #- Code (productcode)

    my $lproductcode = $frame1->Label(
        -text => 'Code',
    )->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padleft => 5,
    );

    my $eproductcode = $frame1->MEntry(
        -width              => 15,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lproductcode, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Name (productname)

    my $lproductname = $frame1->Label(
        -text => 'Name',
    )->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductcode, 8 ],
        -padleft => 5,
    );

    my $eproductname = $frame1->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lproductname, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Line (productline)

    my $lproductline = $frame1->Label(
        -text => 'Line',
    )->form(
        -top  => [ $lproductname, 8 ],
        -left => [ %0,            0 ],
        -padleft => 5,
    );

    my $eproductline = $frame1->MEntry(
        -width              => 28,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lproductline, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ Productlinecode

    my $eproductlinecode = $frame1->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top   => [ '&', $lproductline, 0 ],
        -right => [ '&', $eproductname, 0 ],
    );

    #- Scale (productscale)

    my $lproductscale = $frame1->Label(
        -text => 'Scale',
    )->form(
        -left => [ %0,            0 ],
        -top  => [ $lproductline, 8 ],
        -padleft => 5,
    );

    my $eproductscale = $frame1->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lproductscale, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Vendor (productvendor)

    my $lproductvendor = $frame1->Label(
        -text => 'Vendor',
    )->form(
        -top  => [ $lproductscale, 8 ],
        -left => [ %0,             0 ],
        -padleft => 5,
    );

    my $eproductvendor = $frame1->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lproductvendor, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Stock (quantityinstock)

    my $lquantityinstock = $frame1->Label(
        -text => 'Stock',
    )->form(
        -top  => [ $lproductvendor, 8 ],
        -left => [ %0,              0 ],
        -padleft => 5,
    );

    my $equantityinstock = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lquantityinstock, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- Buy price (buyprice)

    my $lbuyprice = $frame1->Label(
        -text => 'Buy price',
    )->form(
        -top  => [ $lquantityinstock, 8 ],
        -left => [ %0,                0 ],
        -padleft => 5,
    );

    my $ebuyprice = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lbuyprice, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- MSRP (msrp)
    my $lmsrp = $frame1->Label(
        -text => 'MSRP',
    )->form(
        -top  => [ $lbuyprice, 8 ],
        -left => [ %0,         0 ],
        -padleft => 5,
    );

    my $emsrp = $frame1->MEntry(
        -width              => 8,
        -justify            => 'right',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    )->form(
        -top  => [ '&', $lmsrp, 0 ],
        -left => [ %0,  $f1d ],
    );

    # Frame 2

    my $frame2 = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    )->grid(
        -row    => 1,
        -column => 0,
        -sticky => 'nsew',
        -ipadx  => 3,
        -ipady  => 3,
    );

    # Font
    my $my_font = $eproductcode->cget('-font');

    # Products
    my $tproductdescription = $frame2->Scrolled(
        'Text',
        -width      => 45,
        -height     => 4,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font,
    )->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 5 ],
        -padleft => 5,
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'products.conf'
    $self->{controls} = {
        productcode        => [ 'e', undef, $eproductcode ],
        productname        => [ 'e', undef, $eproductname ],
        productline        => [ 'e', undef, $eproductline ],
        productlinecode    => [ 'e', undef, $eproductlinecode ],
        productscale       => [ 'e', undef, $eproductscale ],
        productvendor      => [ 'e', undef, $eproductvendor ],
        quantityinstock    => [ 'e', undef, $equantityinstock ],
        buyprice           => [ 'e', undef, $ebuyprice ],
        msrp               => [ 'e', undef, $emsrp ],
        productdescription => [ 'e', undef, $tproductdescription ],
    };

    # Required fields: fld_name => [#, Label]
    # If there is no value in the screen for this fields show a dialog message
    $self->{rq_controls} = {
        productcode        => [ 0, '  Product code' ],
        productname        => [ 1, '  Product name' ],
        productlinecode    => [ 2, '  Product Line' ],
        productscale       => [ 3, '  Product scale' ],
        productvendor      => [ 4, '  Product vendor' ],
        quantityinstock    => [ 5, '  Quantity in stock' ],
        buyprice           => [ 6, '  Buy price' ],
        msrp               => [ 7, '  MSRP' ],
        productdescription => [ 8, '  Product description' ],
    };

    return;
}

1;

=head1 SYNOPSIS

    require App::Fenix::App::Demo::Products;

    my $scr = App::Fenix::App::Demo::Products->new;

    $scr->run_screen($args);

=head2 run_screen

The screen layout

=cut
