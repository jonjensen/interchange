# Copyright 2002-2007 Interchange Development Group and others
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.  See the LICENSE file for details.

UserTag var Order         name global filter
UserTag var Interpolate   1
UserTag var Version       1.12
UserTag var Routine       <<EOR
sub {
	my ($key, $global, $filter) = @_;
	my $value;
	if ($global and $global != 2) {
		$value = $Global::Variable->{$key};
	}
	elsif ($Vend::Session->{logged_in} and defined $Vend::Cfg->{Member}{$key}) {
		$value = $Vend::Cfg->{Member}{$key};
	}
	else {
		$value = (
			$::Pragma->{dynamic_variables}
			? Vend::Interpolate::dynamic_var($key)
			: $::Variable->{$key}
		);
		$value ||= $Global::Variable->{$key} if $global;
	}
	$value = filter_value($filter, $value, $key) if $filter;
	return $value;
}
EOR
