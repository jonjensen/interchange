# Vend::Track - Interchange User Tracking
#
# $Id: Track.pm,v 1.3.4.2 2001-09-11 10:12:07 racke Exp $
#
# Copyright (C) 2000 by Stefan Hornburg <racke@linuxia.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA.

# TODO
# configuration settings
# check if tracking information is available
# tag to add "view product" tracking information
# support for quantity changes
# consider other carts

# DOCUMENTATION
# "CategoryField" should be set
# "DescriptionField" should be set
# flypage should be used

package Vend::Track;
require Exporter;

use vars qw($VERSION);
$VERSION = substr(q$Revision: 1.3.4.2 $, 10);

@ISA = qw(Exporter);

use strict;
use Vend::Data;

sub new {
	my $proto = shift;
	my $class = ref ($proto) || $proto;
	my $self = {actions => []};

	bless ($self, $class);
}

# ACTIONS

sub add_item {
	my ($self,$cart,$item) = @_;

	push (@{$self->{actions}},
		  ['ADDITEM', {code => $item->{'code'},
					   description => item_description($item),
					   category => item_category($item)
					  }]);
}

sub user {
	my ($self) = shift;
	push (@{$self->{actions}}, [@_]);
	return;
}

sub finish_order {
	my ($self) = @_;
	my (@items, $item, $itemout);
	
	foreach my $item (@{$::Carts->{'main'}}) {
		$itemout = {code => $item->{'code'},
					description => item_description($item),
					category => item_category($item),
					quantity => $item->{'quantity'},
					price => item_price($item)
					};
		push (@items, $itemout);
	}
		
	push (@{$self->{actions}}, ['ORDER', {}],
		  ['ORDERINFO', {total => Vend::Interpolate::total_cost (),
					 payment => '',
					 shipmode => Vend::Interpolate::tag_shipping_desc (),
					 items => \@items
					}]);
}

sub view_page {
	my ($self, $page) = @_;

	push (@{$self->{actions}}, ['VIEWPAGE', {page => $page}]);
}

sub view_product {
	my ($self, $code) = @_;

	push (@{$self->{actions}},
		  ['VIEWPROD', {code => $code,
						description => product_description($code),
						category => product_category($code)
					   }]);
}

# HEADER

my %hdrsubs = ('ADDITEM' => sub {my $href = shift; join (',', $href->{'code'}, $href->{'description'});},
			   'ORDER' => sub {my $href = shift; $::Values->{mv_order_number}},
			   'ORDERINFO' => sub {my $href = shift;
							   join ('/',
									 join ("\t", $href->{'total'}, $href->{'payment'}, $href->{'shipmode'}),
									 map {join ("\t", $_->{'code'},
											   $_->{'description'},
											   $_->{'category'},
											   $_->{'quantity'},
											   $_->{'price'})}
									 @{$href->{'items'}});},
			   'VIEWPAGE' => sub {my $href = shift; $href->{'page'}},
			   'VIEWPROD' => sub {my $href = shift; join ("\t", $href->{'code'}, $href->{'description'}, $href->{'category'});});

sub header {
	my ($self) = @_;
	my (@hdr, $href);

	push(@hdr, "SESSION=$Vend::SessionID");
	for my $aref (@{$self->{actions}}) {
		$href = $aref->[1];
		if (exists $hdrsubs{$aref->[0]}) {
			push(@hdr, $aref->[0] . '=' . &{$hdrsubs{$aref->[0]}} ($aref->[1]));
		}
		else {
			push(@hdr, "$aref->[0]=$aref->[1]");
		}
	}
	for(@hdr) {
		s/\n/<LF>/g;
		s/\r/<CR>/g;
	}
	join('&',@hdr);
}

sub std_log {
	my(@parm) = @_;
	my $now = time();
	my $date = POSIX::strftime('%Y%m%d', localtime($now));

	::logData(
		$Vend::Cfg->{TrackFile},
				$date,
				$Vend::SessionName,
				$Vend::Session->{username},
				($CGI::remote_host || $CGI::remote_addr),
				$now,
				$Vend::Session->{source},
				join('&', @parm),
	);
	return;
}

sub filetrack {
	return unless $Vend::Cfg->{TrackFile};
	my ($self) = @_;
	my (@hdr, $href);

	for my $aref (@{$self->{actions}}) {
		$href = $aref->[1];
		if (exists $hdrsubs{$aref->[0]}) {
			push(@hdr, $aref->[0] . '=' . &{$hdrsubs{$aref->[0]}} ($aref->[1]));
		}
		else {
			push(@hdr, "$aref->[0]=$aref->[1]");
		}
	}
	return std_log(@hdr) unless $Vend::Cfg->{TrackSub};
	$Vend::Cfg->{TrackSub}->(@hdr);
}

