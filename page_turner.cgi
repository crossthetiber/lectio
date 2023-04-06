#!/usr/bin/perl

# page_turner.cgi
# first draft 01/2005 - RJF

# This script is based upon the Lectio Perl library which was developed separately. This program
# is intended to be used as a page turning program which will provide navigation tools for use
# with a specific collection. The program will also provide some minor utilities for examining various
# versions of a given selection (e.g. - for reading or printing purposes). The program is a CGI script
# and thus can only be used in the context of a web server/web browser environment.

use CGI qw/:all *div *table *ol *ul *li *b *Tr *script *style/;
use CGI::Pretty qw( :html3 );
use CGI::Carp qw(fatalsToBrowser);
use Lectio;
use strict;


####################
# configuration

my $frame_display = 1;

# "about" URL
my $about_url = '/mathematics/clavius/about/about_page.html';

# URLs and directories
my $script_url = '/mathematics/clavius/cgi-bin/';
my $html_dir = '/shared/websites/main/mathematics/clavius/cgi-bin/';
my $html_url = '/mathematics/clavius/cgi-bin/';
my $css_url = '/mathematics/clavius/cgi-bin/';
my $css_dir = '/shared/websites/main/mathematics/clavius/cgi-bin/';
my $image_url = '/mathematics/clavius/cgi-bin/';
my $image_dir = '/shared/websites/main/mathematics/clavius/cgi-bin';

# top header file
my $header_file_name = 'header.html';
my $header_location = "${html_url}${header_file_name}";
my $header = "${html_dir}${header_file_name}";

# main display vars
my $main_default_image = 'clavius_default.gif';
my $top_frame_height = '55px';
my $bottom_frame_height = '700px';

# nav menu vars
my $top_selection_type = 'Volume';
my $menu_background_image = 'clavius_spheres2.gif';
my %name_patterns = ('Volume Section', '0|x|0', 'Work', '0|x', 'Work Section', '0|0|x|0', 'Chapter', '0|0|x|0', 'Page', '0|0|0|x');
my %name_colors = ('Volume', '#990000', 'Volume Section', '#CC3333', 'Work', '#006600', 'Work Section', '#6633CC', 'Chapter', '#6633CC');
my $hover_color = '#000000';
my @terminal_menu_levels = ('Volume Section', 'Work Section', 'Chapter');

# selection vars
my $book_context_placement = '1'; # this configuration will render the initial display as a book with right and left hand panes

# content type
my $image_content = '0';
my $audio_content = '0';
my $manuscript_content = '1';

# display panel vars
my $initial_display_type_name = 'small_jpeg';
my $initial_display_height = '500px';
my $initial_display_width = '306px';
my $zoom_display_type_name = 'medium_jpeg';
my $zoom_display_height = '1280px';
my $zoom_display_width = '783px';
my $print_type_name = 'large_jpeg';
my $print_display_height = '885px';
my $print_display_width = '541px';

# goto page variables
my $group_name = 'Work';
my $sub_group_name = 'Page';
my %sub_group_names = ('Work Section' => '0|0|x|x', 'Chapter' => '0|0|x|x'); # these should be children of the named group

# full text help text
my $full_text_help = 'view English translation';


##########
# main

my $global_opts = init_param();

if ($global_opts->{'output_navmenu'}) {

	output_navmenu();

} elsif ($global_opts->{'output_main'}) {

	if ($manuscript_content) {

		output_manuscript(rh_id => $global_opts->{'rh_id'}, lh_id => $global_opts->{'lh_id'});

	} elsif ($image_content) {

	} elsif ($audio_content) {

	}

} elsif ($global_opts->{'output_zoom'}) {

	output_zoom_page(selection_id => $global_opts->{'selection_id'});

} elsif ($global_opts->{'output_print'}) {

	output_print_page(selection_id => $global_opts->{'selection_id'});

} elsif ($global_opts->{'output_page_goto'}) {

	output_page_goto();

} elsif ($global_opts->{'output_full_text'}) {

	full_text_window(selection_id => $global_opts->{'selection_id'});

} else {

	output_framed_display();

}

##############
# subroutines

sub init_param {

	my %global_opts = ();
	$global_opts{'cgi_input'} = CGI->new();
	$global_opts{'cgi_output'} = CGI->new();
	$global_opts{'output_navmenu'} = $global_opts{'cgi_input'}->param('output_navmenu');
	$global_opts{'output_main'} = $global_opts{'cgi_input'}->param('output_main');
	$global_opts{'output_zoom'} = $global_opts{'cgi_input'}->param('output_zoom');
	$global_opts{'output_print'} = $global_opts{'cgi_input'}->param('output_print');
	$global_opts{'output_page_goto'} = $global_opts{'cgi_input'}->param('output_page_goto');
	$global_opts{'output_full_text'} = $global_opts{'cgi_input'}->param('output_full_text');
	$global_opts{'rh_id'} = $global_opts{'cgi_input'}->param('rh_id');
	$global_opts{'lh_id'} = $global_opts{'cgi_input'}->param('lh_id');
	$global_opts{'selection_id'} = $global_opts{'cgi_input'}->param('selection_id');
	$global_opts{'noresize'} = $global_opts{'cgi_input'}->param('noresize');
	$global_opts{'group_id'} = $global_opts{'cgi_input'}->param('group_id');
	$global_opts{'page_id'} = $global_opts{'cgi_input'}->param('page_id');
	
	return \%global_opts;

}

sub output_goto_data {

	my %local_opts = @_;
	my @group_selections = Lectio::Selection->get_selections(type => $group_name, sort => 'ascension');
	print $global_opts->{'cgi_output'}->start_script({-type=>'text/javascript'});
	print "\nvar group = new Array;\n";
	print "var label = new Array;\n";
	foreach my $group_selection_id (@group_selections) {
		my $group_selection = Lectio::Selection->new(id => $group_selection_id);
		my @child_ids = ();
		my @group_selection_children = $group_selection->children(sort => 'ascension');
		foreach my $group_selection_children_id (@group_selection_children) {
			my $child_selection = Lectio::Selection->new(id => $group_selection_children_id);
			my $child_selection_name = $child_selection->selection_name();
			if (exists($sub_group_names{(Lectio::Selection::Type->new(id => $child_selection->type_id()))->type_name()})) {
				my $name_pattern = $sub_group_names{(Lectio::Selection::Type->new(id => $child_selection->type_id()))->type_name()};
				my @name_sections = split(/\|/, $name_pattern);
				my $number_sections = scalar(@name_sections);
				my $selection_name;
				for (my $i = 0; $i < $number_sections; $i++) {
					if ($name_sections[$i] eq 'x') {
						my $regex_pattern;
						for (my $y = 0; $y < $number_sections; $y++) {
							if ($y == $i) { # x marks the spot
								unless ($y == $number_sections - 1) {
									$regex_pattern .= '(.+)?\s*\|';
								} else {
									$regex_pattern .= '(.+)?\s*';
								}
							} else {
								unless ($y == $number_sections - 1) {
									$regex_pattern .= '.+?\s*\|';
								} else {
									$regex_pattern .= '.+?\s*';
								}
							}
						}
						$child_selection_name =~ /$regex_pattern/;
						my $addition = "$1";
						$addition =~ s/^\s*//;
						$addition =~ s/\s*$//;
						$selection_name .= " $addition - ";
					}
				}
				$selection_name =~ s/^\s*//;
				$selection_name =~ s/\s-\s$//;
				push(@child_ids, $group_selection_children_id);
				print "label[$group_selection_children_id] = \"$selection_name\"\;\n";
			}
			# check for one level down of children, no more - no less
			if (scalar($child_selection->children()) >= 1) {
				my @grandchildren = $child_selection->children(sort => 'ascension');
				my $name_pattern = $sub_group_names{(Lectio::Selection::Type->new(id => $child_selection->type_id()))->type_name()};
				foreach my $grandchild_id (@grandchildren) {
					my $grandchild_selection = Lectio::Selection->new(id => $grandchild_id);
					my $grandchild_name = $grandchild_selection->selection_name();
					my @name_sections = split(/\|/, $name_pattern);
					my $number_sections = scalar(@name_sections);
					my $selection_name;
					for (my $i = 0; $i < $number_sections; $i++) {
						if ($name_sections[$i] eq 'x') {
							my $regex_pattern;
							for (my $y = 0; $y < $number_sections; $y++) {
								if ($y == $i) { # x marks the spot
									unless ($y == $number_sections - 1) {
										$regex_pattern .= '(.+)?\s*\|';
									} else {
										$regex_pattern .= '(.+)?\s*';
									}
								} else {
									unless ($y == $number_sections - 1) {
										$regex_pattern .= '.+?\s*\|';
									} else {
										$regex_pattern .= '.+?\s*';
									}
								}
							}
							$grandchild_name =~ /$regex_pattern/;
							my $addition = "$1";
							$addition =~ s/^\s*//;
							$addition =~ s/\s*$//;
							$selection_name .= " $addition - ";
						}
					}
					$selection_name =~ s/^\s*//;
					$selection_name =~ s/\s-\s$//;
					push(@child_ids, $grandchild_id);
					print "label[$grandchild_id] = \"$selection_name\"\;\n";
				}
			}
		}
		if (scalar(@child_ids)) {
			print "\n";
			print "group[$group_selection_id] = [";
			my $child_id_string;
			foreach my $child_id (@child_ids) {
				$child_id_string .= "$child_id, ";
			}
			chop($child_id_string);
			chop($child_id_string);
			print "$child_id_string";
			print "]\n";
		}
	}
	print $global_opts->{'cgi_output'}->end_script();
}

sub output_popup_goto {

	# output initial graphic
	print $global_opts->{'cgi_output'}->a({href => '#', 'onMouseOver' => "sitb_showLayer(\'bookpopover\'); return false;", onMouseOut => "sitb_doHide('bookpopover'); return false;"}, img({src => "${image_url}goto_page.gif", border => '0', height => '20px', width => '100px', id => 'prodimage'})); 

	# gather top group labels and ids
	my @group_selections = Lectio::Selection->get_selections(type => $group_name, sort => 'ascension');
	my %group_labels = ();
	my @group_ids = ();
	foreach my $group_selection_id (@group_selections) {
		my $current_selection = Lectio::Selection->new(id => $group_selection_id);
		my $current_name = $current_selection->selection_name();
		my $outer_regex = $name_patterns{$group_name};
		$outer_regex =~ s/0/\.\+\?/g;
		$outer_regex =~ s/x/\\s\*\(\.\+\)\?\\s\*/;
		$outer_regex =~ s/\|/\\\|/g;
		$current_name =~ /$outer_regex/;
		my $regex_name = "$1";
		$regex_name =~ s/\s*$//;
		if (scalar($current_selection->children()) >= 1) {
			$group_labels{$current_selection->id()} = $regex_name;
			push(@group_ids, $current_selection->id());
		}
	}

	print $global_opts->{'cgi_output'}->start_div({id => 'bookpopover', style => 'position: absolute; z-index:1999; left:-1000px; top: -1000px; visibility: hidden; width: 235px; height: 100px;', onMouseOver => "sitb_showLayer(\'bookpopover\')", onLoad => "sitb_hideLayer(\'bookpopover\');", visibility => 'hide'});

	print $global_opts->{'cgi_output'}->start_div({ style => 'border: 1px solid #ACA976; background-color:#FFFFFF; font-family: Arial;', onMouseOver => "sitb_showLayer(\'bookpopover\')"});
	
	print $global_opts->{'cgi_output'}->start_table({width => "100%", height => "100%", border => "0", cellpadding => "1", cellspacing => "0"});
	print $global_opts->{'cgi_output'}->start_Tr({valign => 'top'});
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->b({style => "font-size: 12px;"}, 'Go To Specific Page');
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td({align => 'right'});
	print $global_opts->{'cgi_output'}->a({href => '#', style => "text-decoration:none; color: black;"}, span({style => "font-size: 10px;", onclick => "sitb_doHide('bookpopover')"}, 'close menu'));
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->start_Tr();
	print $global_opts->{'cgi_output'}->start_td({colspan => '2'});
	print $global_opts->{'cgi_output'}->start_form({name => "strip_form", method => "GET", action => "${script_url}page_turner.cgi", target => 'main_display'});
	print $global_opts->{'cgi_output'}->input({type => "hidden", name => "output_page_goto", id => "page_goto_flag", value => "1"});
	print $global_opts->{'cgi_output'}->start_table({width => "100%", height => "100%", cellspacing => "0", cellpadding => "2", border => "0"});
	print $global_opts->{'cgi_output'}->start_Tr();
	print $global_opts->{'cgi_output'}->td({width => "10%", align => "right", style => 'padding-bottom: 10px'}, b({style => "font-size: 12px;"}, "${group_name}:&nbsp;&nbsp;"));
	print $global_opts->{'cgi_output'}->start_td({valign => 'middle', colspan => '2', style => 'padding-bottom: 10px'});
	print $global_opts->{'cgi_output'}->popup_menu({-name=>'group_id',
							-id=>'group_menu',
							-style=>'font-family: Arial; font-size: 10px; width: 180px;',
							-onchange=>'change_page_menu()',
							-values=>[@group_ids],
							-labels=>\%group_labels});
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->start_Tr();
	# end new
	print $global_opts->{'cgi_output'}->td({width => "10%", align => "right"}, b({style => "font-size: 12px;"}, "${sub_group_name}:&nbsp;&nbsp;"));
	print $global_opts->{'cgi_output'}->start_td({valign => 'middle'});
	print $global_opts->{'cgi_output'}->popup_menu({-name=>'page_id',
							-id=>'page_menu',
							-size=> '1',
							-style=> 'font-family: Arial; font-size: 9px; width: 160px;'});
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td({valign => 'middle'});
	print $global_opts->{'cgi_output'}->input({type => 'image', src => "${image_url}go.gif", height => '20', alt => 'Go!', border => '0', width => '20', value => 'go', name => 'go'});
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->end_table();
	print $global_opts->{'cgi_output'}->end_form();
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->end_table();
	print $global_opts->{'cgi_output'}->end_div();
	print $global_opts->{'cgi_output'}->end_div();
	print $global_opts->{'cgi_output'}->end_div();
	print $global_opts->{'cgi_output'}->end_div();

	# initialize form
	print $global_opts->{'cgi_output'}->start_script({-type=>'text/javascript'});
	print "change_page_menu();\n";
	print $global_opts->{'cgi_output'}->end_script();
	
}

sub output_page_goto {

	my %local_opts = @_;

	my $current_page_selection = Lectio::Selection->new(id => $global_opts->{'page_id'});
	my $current_page_context = $current_page_selection->context();
	my ($rh_id, $lh_id);
	if ($current_page_context eq 'right hand') {
		$lh_id = $current_page_selection->previous_selection();
		$rh_id = $global_opts->{'page_id'};
	} elsif ($current_page_context eq 'left hand') {
		$rh_id = $current_page_selection->next_selection();
		$lh_id = $global_opts->{'page_id'};
	}

	output_manuscript(rh_id => $rh_id, lh_id => $lh_id);	


}

sub output_framed_display {

	output_initial_html(body => '0', base => '1', title => 'Christoph Clavius Opera Mathematica');
	print $global_opts->{'cgi_output'}->start_frameset({rows => "${top_frame_height}, ${bottom_frame_height}", border => '1'});
	print $global_opts->{'cgi_output'}->frame({frameborder => '1', src => "$header_location", noresize => '1', scrolling => 'no'});
	print $global_opts->{'cgi_output'}->start_frameset({cols => '180px, 500px'});
	print $global_opts->{'cgi_output'}->frame({frameborder => '1', src =>"${script_url}page_turner.cgi?output_navmenu=2", noresize => '1', scrolling => 'yes'});
	print $global_opts->{'cgi_output'}->frame({frameborder => '1', src =>"${image_url}${main_default_image}", name => 'main_display'});
	print $global_opts->{'cgi_output'}->end_frameset();
	print $global_opts->{'cgi_output'}->end_frameset(); 
	print $global_opts->{'cgi_output'}->end_html();

}

sub output_initial_html {

	my %local_opts = @_;
	my $title = $local_opts{title};
	my $background_image = "${image_url}" . $local_opts{background};
	my $onload_event = $local_opts{onload};
	print $global_opts->{'cgi_output'}->header();
	if ($local_opts{'body'} && $local_opts{'base'} == 1) {
		print $global_opts->{'cgi_output'}->start_html(-title => "$title",
														-background => "$background_image",
														-onLoad => "$onload_event",
														-bgcolor => $local_opts{bgcolor}
														);
	} elsif ($local_opts{'body'} && $local_opts{'base'} == 0) {

		print "<html>\n";
		print "\t<head><title>Christoph Clavius Opera Mathematica</title>\n";
		print '</head>';
		print "\n<body background = \"$background_image\"\n";

	} else { # send out all but the body tag

		my $start_html = $global_opts->{'cgi_output'}->start_html(-title => "$title",
																);
		$start_html =~ s/<body>//;
		print "$start_html\n";

	}

}

sub output_final_html {

	print $global_opts->{'cgi_output'}->end_html();

}

sub output_header {

	my %local_opts = @_; 
	open(HEADER, "$header") or croak("Header file could not be opened. $!");
	my $output;

	while (<HEADER>) {

		$output = "$_\n";

	}

	if ($local_opts{'return'}) {

		return $output;

	} else {

		print $output;

	}

}

sub output_navmenu {


	output_initial_html(body => '1', base => '0', title => 'Christoph Clavius Opera Mathematica', background => "$menu_background_image");
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">	', "\n";
	output_javascript();
	output_css();
	# Rob here
	if ($about_url =~ /^\/mathematics/) {
		print $global_opts->{'cgi_output'}->a({-href=>$about_url, target=>'main_display', class=>'about_line'}, 'About');
		print ' Clavius and this project.';
		print $global_opts->{'cgi_output'}->br();
		print $global_opts->{'cgi_output'}->br();
	}
	print $global_opts->{'cgi_output'}->img({style => 'border: none', src => "${image_url}main_menu.gif"});
	# print $global_opts->{'cgi_output'}->h1({style => 'font-family: arial; font-size: 16px;'}, 'Main Menu');
	my @top_level_selections = Lectio::Selection->get_selections(type => $top_selection_type, sort => 'ascension');
	print $global_opts->{'cgi_output'}->start_style({type => 'text/css'});
	print "\n";
	foreach my $style_class (keys %name_colors) {
		my $orig_type_name = $style_class;
		$style_class =~ s/\s/_/g;
		$style_class = lc($style_class);
		print "a.$style_class:link {\n";
		print "\tcolor: $name_colors{$orig_type_name}\;\n";
		print "\ttext-decoration: none\;\n";
		print "}\n";
		print "\n";
		print "a.$style_class:visited {\n";
		print "\tcolor: $name_colors{$orig_type_name}\;\n";
		print "\ttext-decoration: none\;\n";
		print "}\n";
		print "\n";
		print "a.$style_class:active {\n";
		print "\tcolor: $name_colors{$orig_type_name}\;\n";
		print "\ttext-decoration: none\;\n";
		print "}\n";
		print "\n";
		print "a.$style_class:hover {\n";
		print "\ttext-decoration: underline\;\n";
		print "\tcolor: $hover_color\;\n";
		print "}\n";
		print "\n";
	}
	print "\n";
	print $global_opts->{'cgi_output'}->end_style();
	if ($manuscript_content) {
		if ($global_opts->{'output_navmenu'} == 2) {
			output_goto_data();
		}
	}
	print $global_opts->{'cgi_output'}->start_ul({class => 'outermost'});
	foreach my $top_level_selection_id (@top_level_selections) {
		my $top_level_selection = Lectio::Selection->new(id => $top_level_selection_id);
		my $top_level_type_id = $top_level_selection->type_id();
		my ($lh_id, $rh_id, $top_level_selection_url);
		if ($top_level_selection) {
			my $top_level_selection_context = $top_level_selection->context();
			if ($manuscript_content) { # this is a book or series of books
				if ($top_level_selection_context eq 'right hand') {

					$lh_id = $top_level_selection->previous_selection();
					$rh_id = $top_level_selection->id();

				} elsif ($top_level_selection_context eq 'left hand') {

					$rh_id = $top_level_selection->next_selection();
					$lh_id = $top_level_selection->id();

				}
				$top_level_selection_url = "${script_url}page_turner.cgi?output_main=1&lh_id=$lh_id&rh_id=$rh_id";
			}
		}
		
		my $top_level_name = $top_level_selection->selection_name();
		my $top_level_color = $name_colors{$top_selection_type};
		my $top_level_style_name = lc($top_selection_type);
		$top_level_style_name =~ s/\s/_/g;
		print $global_opts->{'cgi_output'}->start_li({style => "color: $top_level_color"});
		print $global_opts->{'cgi_output'}->img({onclick => "area_expand(\"$top_level_name\")", src => "${image_url}plus.gif", id => "$top_level_name"});
		if ($rh_id =~ /\d+/ && $lh_id =~ /\d+/) {
			print $global_opts->{'cgi_output'}->a({href => "$top_level_selection_url", target => 'main_display', class => "$top_level_style_name"}, b("$top_level_name"));
		} else {
			print $global_opts->{'cgi_output'}->b("$top_level_name");
		}
		output_children($top_level_selection, top_level_type_name => $top_selection_type);
		print $global_opts->{'cgi_output'}->end_li();
	}
	print $global_opts->{'cgi_output'}->end_ul();
	if ($manuscript_content) {
		if ($global_opts->{'output_navmenu'} == 2) {
			print $global_opts->{'cgi_output'}->br();
			output_popup_goto();
		}
	}
	output_final_html();

}

sub output_children {

	my $prior_level_selection = shift;
	my %local_opts = @_;

	# determine selection types
	my %selection_types = Lectio::Selection::Type->get_types();

	my $prior_level_name = $prior_level_selection->selection_name(); 
	my $prior_level_type_id = $prior_level_selection->type_id();
	my $prior_level_type_name = $selection_types{$prior_level_type_id};
	my $div_name;
	unless ($prior_level_type_name eq $local_opts{'top_level_type_name'}) {
		my $outer_regex = $name_patterns{$prior_level_type_name};
		$outer_regex =~ s/0/\.\+\?/g;
		$outer_regex =~ s/x/\\s\*\(\.\+\)\?\\s\*/;
		$outer_regex =~ s/\|/\\\|/g;
		$prior_level_name =~ /$outer_regex/;
		$div_name = "$1";
		$div_name =~ s/\s*$//;
	} else {
		$div_name = $prior_level_name;
	}
		


		# this section will be repeatable for each "child" section
		my @children = $prior_level_selection->children(sort => 'ascension');
		print $global_opts->{'cgi_output'}->start_div({id => "${div_name}_sub", switch => 'off', style => 'display:none'});
		print $global_opts->{'cgi_output'}->start_ul({class => 'inner'});
		foreach my $child_id (@children) {
			my $child_selection = Lectio::Selection->new(id => $child_id);
			my @grandchildren = $child_selection->children(sort => 'ascension');
			my $child_selection_name = $child_selection->selection_name();
			my $child_type_id = $child_selection->type_id();
			my $child_type_name = $selection_types{$child_type_id};
			my ($lh_id, $rh_id, $child_selection_url);
			if ($child_selection) {
				my $child_selection_context = $child_selection->context();
				if ($manuscript_content) { # this is a book or series of books
					if ($child_selection_context eq 'right hand') {

						$lh_id = $child_selection->previous_selection();
						$rh_id = $child_selection->id();

					} elsif ($child_selection_context eq 'left hand') {

						$rh_id = $child_selection->next_selection();
						$lh_id = $child_selection->id();

					}
					$child_selection_url = "${script_url}page_turner.cgi?output_main=1&lh_id=$lh_id&rh_id=$rh_id";
				}
			}
			my $regex = $name_patterns{$child_type_name};
			$regex =~ s/0/\.\+\?/g;
			$regex =~ s/x/\\s\*\(\.\+\)\?\\s\*/;
			$regex =~ s/\|/\\\|/g;
			$child_selection_name =~ /$regex/;
			my $child_regex_name = "$1";
			$child_regex_name =~ s/\s*$//;
			my $child_color = $name_colors{$child_type_name};
			my $child_style_name = lc($child_type_name);
			$child_style_name =~ s/\s/_/g;
			print $global_opts->{'cgi_output'}->start_li({style => "color: $child_color"});
			my $skip_children = 0;
			foreach my $terminal_menu_level (@terminal_menu_levels) {
				if ($child_type_name eq $terminal_menu_level) {
					$skip_children = 1;
				}
			}
			if (scalar(@grandchildren) && $skip_children == 0) {
				print $global_opts->{'cgi_output'}->img({onclick => "area_expand(\"$child_regex_name\")", src => "${image_url}plus.gif", id => "$child_regex_name"});
				if ($rh_id =~ /\d+/ && $lh_id =~ /\d+/) {
					print $global_opts->{'cgi_output'}->a({href => "$child_selection_url", target => 'main_display', class => "$child_style_name"}, b("$child_regex_name"));
				} else {
					print $global_opts->{'cgi_output'}->b("$child_regex_name");
				}
				output_children($child_selection);
			} else {
				if ($rh_id =~ /\d+/ && $lh_id =~ /\d+/) {
					print $global_opts->{'cgi_output'}->a({href => "$child_selection_url", target => 'main_display', class => "$child_style_name"}, b("$child_regex_name"));
				} else {
					print $global_opts->{'cgi_output'}->b("$child_regex_name");
				}
			}
			print $global_opts->{'cgi_output'}->end_li();
		}
		print $global_opts->{'cgi_output'}->end_ul();
		print $global_opts->{'cgi_output'}->end_div();

}

sub output_manuscript {

	my %local_opts = @_;

	# get the selection paths
	my $RH_selection = Lectio::Selection->new(id => $local_opts{rh_id});
	my $RH_path = $RH_selection->selection_path(pos => 'current', type_name => $initial_display_type_name);
	my $RH_zoom_path = $RH_selection->selection_path(pos => 'current', type_name => $zoom_display_type_name);
	my $RH_name = $RH_selection->selection_name();
	$RH_name =~ s/\|/-/g;
	my $LH_selection = Lectio::Selection->new(id => $local_opts{lh_id});
	my $LH_path = $LH_selection->selection_path(pos => 'current', type_name => $initial_display_type_name);
	my $LH_zoom_path = $LH_selection->selection_path(pos => 'current', type_name => $zoom_display_type_name);
	my $LH_name = $LH_selection->selection_name();
	$LH_name =~ s/\|/-/g;

	# find out what is next and previous
	my $next_selection_id = $RH_selection->next_selection();
	my $next_selection = Lectio::Selection->new(id => $next_selection_id);
	my $next_selection_name;
	if ($next_selection) {
		$next_selection_name = $next_selection->selection_name();
		$next_selection_name =~ s/\|/-/g;
	}
	my $previous_selection_id = $LH_selection->previous_selection();
	my $previous_selection = Lectio::Selection->new(id => $previous_selection_id);
	my $previous_selection_name;
	if ($previous_selection) {
		$previous_selection_name = $previous_selection->selection_name();
		$previous_selection_name =~ s/\|/-/g;
	}
	my $next_url;
	my $next_available = 0;
	if ($next_selection) { # should always be a left hand image, or nothing

		$next_url = "${script_url}page_turner.cgi?output_main=1&lh_id=$next_selection_id";
		my $rh_id = $next_selection->next_selection();
		$next_url .= "&rh_id=$rh_id";
		if ($rh_id =~ /^\d+$/ && $next_selection_id =~ /^\d+$/) {
			$next_available = 1;
		}
	} 

	my $previous_url;
	my $previous_available = 0;	
	if ($previous_selection) { # should always be a right hand image or nothing
	
		$previous_url = "${script_url}page_turner.cgi?output_main=1&rh_id=$previous_selection_id";
		my $lh_id = $previous_selection->previous_selection();
		$previous_url .= "&lh_id=$lh_id";
		if ($lh_id =~ /^\d+$/ && $previous_selection_id =~ /^\d+$/) {
			$previous_available = 1;
		}

	}

	# output the page
	output_initial_html(body => '1', base => '1', title => 'Christoph Clavius Opera Mathematica');
	output_javascript();
	print $global_opts->{'cgi_output'}->start_table({border => '0', cellpadding => '1', cellspacing => '0'});
	print $global_opts->{'cgi_output'}->start_Tr();
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->span({style => 'color: grey; font: normal normal normal 9px Arial;'}, "$LH_name");
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->span({style => 'color: grey; font: normal normal normal 9px Arial;'}, "$RH_name");
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->start_Tr();
	print $global_opts->{'cgi_output'}->start_td({valign => 'top'});
	if ($previous_available) {
		print $global_opts->{'cgi_output'}->a({href => "$previous_url"}, img({src => "${image_url}left_arrow.gif", alt => "$previous_selection_name", title => "$previous_selection_name", style => 'vertical-align: top; border: none'}));
	}
	print $global_opts->{'cgi_output'}->br();
	print $global_opts->{'cgi_output'}->br();
	if ($LH_selection->full_text()) {
		print $global_opts->{'cgi_output'}->a({href => "javascript:full_text_window(\'${script_url}page_turner.cgi?output_full_text=1&selection_id=$local_opts{lh_id}\', \'FullTextSelection\')"}, img({src => "${image_url}full_text.gif", alt => "$full_text_help", title => "$full_text_help", style => 'border: none'}));
	}
	print $global_opts->{'cgi_output'}->br();	
	print $global_opts->{'cgi_output'}->br();
	print $global_opts->{'cgi_output'}->a({href => "${script_url}page_turner.cgi?output_print=1&selection_id=$local_opts{lh_id}", target => '_blank'}, img({src => "${image_url}printer.gif", alt => "print this selection", title => "print this selection", style => 'border: none'}));
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->a({href => "javascript:open_left(\'${script_url}page_turner.cgi?selection_id=$local_opts{lh_id}&output_zoom=1\', \'Left_Win\')"}, img({src => "$LH_path", alt => "$LH_name", title => "$LH_name", width => "$initial_display_width", height => "$initial_display_height", style=>'margin-right: 2px; border: 1px solid black;'}));
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td();
	print $global_opts->{'cgi_output'}->a({href => "javascript:open_right(\'${script_url}page_turner.cgi?selection_id=$local_opts{rh_id}&output_zoom=1\', \'Right_Win\')"}, img({src => "$RH_path", alt => "$RH_name", title => "$RH_name", width => "$initial_display_width", height => "$initial_display_height", style=>'margin-left: 2px; border: 1px solid black'}));
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->start_td({valign => 'top'});
	if ($next_available){
		print $global_opts->{'cgi_output'}->a({href => "$next_url"}, img({src => "${image_url}right_arrow.gif", alt => "$next_selection_name", title => "$next_selection_name", style => 'vertical-align: top; border: none'}));
	}
	print $global_opts->{'cgi_output'}->br();
	print $global_opts->{'cgi_output'}->br();
	if ($RH_selection->full_text()) {
		print $global_opts->{'cgi_output'}->a({href => "javascript:full_text_window(\'${script_url}page_turner.cgi?output_full_text=1&selection_id=$local_opts{rh_id}\', \'FullTextSelection\')"}, img({src => "${image_url}full_text.gif", alt => "$full_text_help", title => "$full_text_help", style => 'border: none'}));
	}
	print $global_opts->{'cgi_output'}->br();
	print $global_opts->{'cgi_output'}->br();
	print $global_opts->{'cgi_output'}->a({href => "${script_url}page_turner.cgi?output_print=1&selection_id=$local_opts{rh_id}", target => '_blank'}, img({src => "${image_url}printer.gif", alt => "print this selection", title => "print this selection", style => 'border: none'}));
	print $global_opts->{'cgi_output'}->end_td();
	print $global_opts->{'cgi_output'}->end_Tr();
	print $global_opts->{'cgi_output'}->end_table();
	output_final_html();

}

sub output_print_page {

	my %local_opts = @_;

	my $print_selection = Lectio::Selection->new(id => $local_opts{selection_id});
	my $print_selection_path = $print_selection->selection_path(pos => 'current', type_name => $print_type_name);
	my $print_selection_name = $print_selection->selection_name();
	$print_selection_name =~ s/\|/-/g;
	output_initial_html(body => '1', base => '1', title => "$print_selection_name", onload => "window.print_selection()", bgcolor => "#999999");	
	output_javascript();
	print $global_opts->{'cgi_output'}->img({src => "$print_selection_path", height => "$print_display_height", width => "$print_display_width", style => "border: 1px solid black;"});
	output_final_html();

}

sub full_text_window {

	my %local_opts = @_;

	my $full_text_selection = Lectio::Selection->new(id => $local_opts{selection_id});

	unless ($global_opts->{'noresize'}) {
        output_initial_html(body => '1', base => '1', title => 'Christoph Clavius Opera Mathematica', bgcolor => "#FFFFFF");
    } else {
        output_initial_html(body => '1', base => '1', title => 'Christoph Clavius Opera Mathematica', bgcolor => "#FFFFFF");
    }
	output_javascript();
	output_css();

	print $global_opts->{'cgi_output'}->a({href => "#", onClick => 'window.close()'}, img({src => "${image_url}close_window_clear.gif", style => 'border: none'}));	
	print '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
	print $global_opts->{'cgi_output'}->a({href => "#", onClick => 'window.print()', class => 'print_key'}, 'print this page');

	my $full_text = $full_text_selection->full_text();
	print $global_opts->{'cgi_output'}->pre({class=>'full_text', wrap=>"1"}, $full_text);

	output_final_html();

}

sub output_zoom_page {

	my %local_opts = @_;

	my $zoom_selection = Lectio::Selection->new(id => $local_opts{selection_id});
	my $zoom_next_selection_id = $zoom_selection->next_selection();
	my $zoom_next_selection = Lectio::Selection->new(id => $zoom_next_selection_id);
	my $next_selection_id = $zoom_next_selection->id();
	my $zoom_previous_selection_id = $zoom_selection->previous_selection();
	my $zoom_previous_selection = Lectio::Selection->new(id => $zoom_previous_selection_id);
	my $previous_selection_id = $zoom_previous_selection->id();
	my $zoom_selection_path = $zoom_selection->selection_path(pos => 'current', type_name => $zoom_display_type_name);
	my $next_selection_url = "${script_url}page_turner.cgi?selection_id=${next_selection_id}&output_zoom=1&noresize=1";
	my $previous_selection_url = "${script_url}page_turner.cgi?selection_id=${previous_selection_id}&output_zoom=1&noresize=1";

	unless ($global_opts->{'noresize'}) {
		output_initial_html(body => '1', base => '1', title => 'Christoph Clavius Opera Mathematica', onload => "resize()", bgcolor => "#999999");
	} else {
		output_initial_html(body => '1', base => '1', title => 'Christoph Clavius Opera Mathematica', bgcolor => "#999999");
	}
	output_javascript();
	print $global_opts->{'cgi_output'}->a({href => "#", onClick => 'window.close()'}, img({src => "${image_url}close_window.gif", style => 'border: none'}));
	print $global_opts->{'cgi_output'}->start_div({align => 'right'});
	if ($zoom_previous_selection) {
		print $global_opts->{'cgi_output'}->a({href => "$previous_selection_url"}, img({src => "${image_url}grey_left.gif", alt => 'previous selection', title => 'previous selection', style => 'border: none'}));
	}
	print '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
	if ($zoom_next_selection) {
		print $global_opts->{'cgi_output'}->a({href => "$next_selection_url"}, img({src => "${image_url}grey_right.gif", alt => 'next selection', title => 'next selection', style => 'border: none'}));
	}
	print $global_opts->{'cgi_output'}->end_div();
	print $global_opts->{'cgi_output'}->img({src => "$zoom_selection_path", height => "$zoom_display_height", width => "$zoom_display_width", style => "border: 1px solid black;"});
	print $global_opts->{'cgi_output'}->a({href => "#", onClick => 'window.close()'}, img({src => "${image_url}close_window.gif", style => 'border: none'}));
	print $global_opts->{'cgi_output'}->start_div({align => 'right'});
	if ($zoom_previous_selection) {
		print $global_opts->{'cgi_output'}->a({href => "$previous_selection_url"}, img({src => "${image_url}grey_left.gif", alt => 'previous selection', title => 'previous selection', style => 'border: none'}));
	}
	print '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
	if ($zoom_next_selection) {
		print $global_opts->{'cgi_output'}->a({href => "$next_selection_url"}, img({src => "${image_url}grey_right.gif", alt => 'next selection', title => 'next selection', style => 'border: none'}));
	}
	print $global_opts->{'cgi_output'}->end_div();
	output_final_html();

}

sub output_css {

	print "<link rel=\"stylesheet\" href=\"${css_url}page_turner.css\" type=\"text/css\">\n";

}

sub output_javascript {

	my $local_opts = shift;

	my $javascript = $global_opts->{'cgi_output'}->start_script({-type=>'text/javascript'});

$javascript .= <<JAVASCRIPT;
<!--
function area_expand (area_name) {
	var current_expand_graphic = document.getElementById(area_name);
	var current_sub_area = document.getElementById(area_name+'_sub');
	var current_sub_area_value = current_sub_area.getAttribute('switch');
	if  (current_sub_area_value == 'on') {
		current_sub_area.setAttribute('switch', 'off');
		current_sub_area.style.display = 'none';
		current_sub_area.style.visibility = 'hidden';
		current_expand_graphic.setAttribute('src', "${image_url}plus.gif");
	} else if (current_sub_area_value == 'off') {
		current_sub_area.setAttribute('switch', 'on');
		current_sub_area.style.display = 'block';
		current_sub_area.style.visibility = 'visible';
		current_expand_graphic.setAttribute('src', "${image_url}minus.gif");
	}
}

var left_Window = null;
var right_Window = null;

function open_right(url, name) {
	if (left_Window && !left_Window.closed) {
		left_Window.focus();
	}
	right_Window=window.open(url, name, "toolbar=no,scrollbars=yes,resizable=yes");
	right_Window.focus();
}

function open_left(url, name) {
	if (right_Window && !right_Window.closed) {
		right_Window.focus();
	}
	left_Window=window.open(url, name, "toolbar=no,scrollbars=yes,resizable=yes");
	left_Window.focus();
}

function print_selection () {

	window.resizeTo (screen.availWidth/2, screen.availHeight);
	window.moveTo (screen.availWidth/3, 0 );
	window.print();

}

function resize() {

	window.resizeTo (screen.availWidth/2, screen.availHeight);
	if (window.name == "Right_Win" ) {
		window.moveTo (screen.availWidth/2, 0 );
	} else {
		window.moveTo (0,0 );
	}
}

function full_text_window (url, name) {

	window.open(url, name, "height=600,width=500,toolbar=no,scrollbars=yes,resizable=yes");

}

function change_page_menu() {

	var group_menu = document.getElementById('group_menu');
	var current_selected_index = group_menu.selectedIndex;
	var current_group_selection = group_menu.options[current_selected_index].value;
	var numChildren = group[current_group_selection].length;
	var page_menu = document.getElementById('page_menu');
	page_menu.length = 0;
	for (i = 0; i < numChildren; i++) {
		var Page_Id = group[current_group_selection][i];
		var Page_label = label[Page_Id];
		page_menu.options[i] = new Option(Page_label, Page_Id);
	}

}

var menuPopoverTimer = null;

function sitb_showLayer(obj) {
  if(document.layer) {
	return; // netscape 4
  }

  if(menuPopoverTimer) {
    clearTimeout(menuPopoverTimer);
    menuPopoverTimer = null;
  }

  var sitb_lyr = sitb_getLayer(obj);
  if(!sitb_lyr) {
    return;
  }
  
  var sitb_img = sitb_getLayer('prodimage');
  if(!sitb_img) {
    return;
  }

  var sitb_x, sitb_y, sitb_temp;
  if(sitb_img.x) {
    sitb_x = sitb_img.x;
  } else {
    sitb_temp = sitb_img;
    sitb_x = sitb_img.offsetLeft;
    while(sitb_temp.offsetParent) {
      sitb_temp = sitb_temp.offsetParent;
      sitb_x += sitb_temp.offsetLeft;
    }
  }
  if(sitb_img.y) {
    sitb_y = sitb_img.y;
  } else {
    sitb_temp = sitb_img;
    sitb_y = sitb_img.offsetTop;
    while(sitb_temp.offsetParent) {
      sitb_temp = sitb_temp.offsetParent;
      sitb_y += sitb_temp.offsetTop;
    }
  }

    sitb_lyr.style.visibility="visible";
    sitb_lyr.style.display="block";

    sitb_lyr.style.left = sitb_x + (sitb_img.width / 15);
    sitb_lyr.style.top = sitb_y + (sitb_img.height / 1.5);
}

function sitb_getLayer(obj) {
  if(document.layers) {
    return document.layers[obj];
  } else if(document.all && !document.getElementById) {
   return document.all[obj];
  } else if(document.getElementById) {
   return document.getElementById(obj);
  } else {
   return null;
  }
}

function sitb_hideLayer(obj) {

  var sitb_lyr = sitb_getLayer(obj);
 
  if(!sitb_lyr) {
    return;
  }

  if(document.layers) {
    sitb_lyr.visibility="hidden";
  } else {
    sitb_lyr.style.display="none";
    sitb_lyr.style.visibility="hidden";
  }

}

function sitb_doHide (obj) {
  if(document.layer) {
    return;
  }
  menuPopoverTimer = setTimeout('sitb_hideLayer("' + obj +'")', 50);  
}

if(document.layers) {
 sitb_hideLayer('bookpopover');
 
}
//-->
JAVASCRIPT

	$javascript .= $global_opts->{'cgi_output'}->end_script();

	print "$javascript\n";

}
