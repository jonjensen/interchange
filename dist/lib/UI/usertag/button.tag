ifndef USERTAG_BUTTON
Variable USERTAG_BUTTON 1
UserTag button Order name src text
UserTag button addAttr
UserTag button attrAlias value text
UserTag button hasEndTag
UserTag button Documentation <<EOD
This tag creates an mv_click button either as a <INPUT TYPE=submit ...>
or a JavaScript-linked <A HREF=....><img src=...> combination.

[button text="Delete item" confirm="Are you sure? src="admin/delete.gif"]
	[comment]
		This is the action, same as [set Delete item] action [/set]
	[/comment]
	[mvtag] Use any Interchange tag here, i.e. ....[/mvtag]
	[perl] # code to delete item [/perl]
[/button]

Parameters:

    name      Name of the variable, by default mv_click. 
             
    src       Image source file. If it is a relative image, the existence
              of the file is checked for
             
    text      The text of the button, also the name of the scratch action
              (VALUE is an alias for TEXT.) 

    border, height, width, vspace, hspace, AND
    align     The image alignment parameters. Border defaults to 0.
             
    form      The name of the form, defaults to document.forms[0] -- be careful!
             
    confirm   The text to use for a JavaScript confirm, if any.
             
    getsize   If true, tries to use Image::Size to add height=Y width=X.
             
    alt       The alt text to be displayed in window.status and balloons.
              Defaults to the same as TEXT.
             
    anchor    Set to the anchor text value, defaults to TEXT
             
    hidetext  Set true if you don't want the anchor displayed


EOD

UserTag button Routine <<EOR
sub {
	my ($name, $src, $text, $opt, $action) = @_;

	my @js;
	my $image;


	if($src) {
		my $dr = $::Variable->{DOCROOT};
		my $id = $::Variable->{IMAGE_DIR} || $Vend::Cfg->{ImageDir};
		$id =~ s:/+$::;
		$id =~ s:/~[^/]+::;
		if(	$src =~ m{^http:}i ) {
				$image = $src;
		}
		elsif( $dr and $id and $src =~ m{^[^/]} and -f "$dr$id/$src" ) {
				$image = $src;
		}
		elsif( $dr and $src =~ m{^/} and -f "$dr/$src" ) {
				$image = "$::Variable->{IMAGE_DIR}/$src";
		}
	}

	my $onclick = '';
	while($action =~ s! \[
						(
							j (?:ava)? s (?:cript)?
						)
						\]
							(.*?)
					  \[ / \1 \]
					  !!xgis
		)
	{
		my $script = $2;
		$script =~ s/\s+$//;
		$script =~ s/^\s+//;
		if($script =~ s/\bonclick\s*=\s*"(.*?)"//is) {
			$onclick = $1;
			next;
		}
		push @js, $script;
	}

	if(! $name or $name eq 'mv_click') {
		$action =~ s/^\s+//;
		$action =~ s/\s+$//;
		$::Scratch->{$text} = $action;
		$name = 'mv_click' if ! $name;
	}
	
	my $out = '';
	my $confirm = '';
	$opt->{extra} = $opt->{extra} ? " $opt->{extra}" : '';
	if($opt->{confirm}) {
		$confirm = "confirm('$opt->{confirm}')";
	}

	if($onclick) {
		$confirm .= ' && ' if $confirm;
		$onclick = qq{onClick="$confirm$onclick"};
	}

	# return submit button if not an image
	if(! $image) {
		$text =~ s/"/&quot;/g;
		$name =~ s/"/&quot;/g;
		if(! $onclick and $confirm) {
			$onclick = qq{ onclick="return $confirm"};
		}
		my $out = $opt->{bold} ? "<B>" : '';
		$out .= qq{<INPUT$opt->{extra} TYPE="submit" NAME="$name" VALUE="$text"$onclick>};
		$out .= "</B>" if $opt->{bold};
		if(@js) {
			$out =~ s/ /join "\n", '', @js, ''/e;
		}
		return $out;
	}

	# If we got here the button is an image
	$text =~ s/"/&quot;/g;
	my $wstatus = $opt->{alt} || $text;
	$wstatus =~ s/'/&#39;/g;
	$name =~ s/"/&quot;/g;

	my $clickname = $name;
	$out .= "</B>" if $opt->{bold};
	my $clickvar = $name;
	if($image and $name eq 'mv_click') {
		$clickvar = $text;
		$clickvar =~ s/\W/_/g;
		$clickname = "mv_click_$clickvar";
		$out = qq{<INPUT TYPE=hidden NAME="mv_click_map" VALUE="$clickvar">};
	}
	
	$out .= qq{<INPUT TYPE=hidden NAME="$clickname" VALUE="">} if $image; 

	my $formname;
	$opt->{form} = 'document.forms[0]'
		if ! $opt->{form};

	$confirm .= ' && ' if $confirm;
	$opt->{border}	= 0 if ! $opt->{border};

	if($opt->{getsize}) {
		eval {
			require Image::Size;
			($opt->{width}, $opt->{height}) = Image::Size::imgsize($image);
		};
	}

	$opt->{align} = 'top' if ! $opt->{align};

	my $position = '';
	for(qw/height width vspace hspace align/) {
		$position .= " $_=$opt->{$_}" if $opt->{$_};
	}

	my $anchor = '';
	unless( $opt->{hidetext}) {
		$anchor = $opt->{anchor} || $text;
		$anchor =~ s/ /&nbsp;/g;
		$anchor = "<b>$anchor</b>";
	}

	$out .= <<EOF;
<A HREF="javascript:void 0"$opt->{extra} onMouseOver="window.status='$wstatus'"
	onClick="$confirm ($opt->{form}.$clickname.value='$text') && $opt->{form}.submit(); return(false);"
	ALT="$wstatus"><IMG ALT="$wstatus" SRC="$src" border=$opt->{border}$position></A>$anchor
EOF

	return $out;
}
EOR
endif
