#!/usr/bin/perl -w 

use strict;
use vars qw ($VERSION);

# the version of this program/package
$VERSION = "0.22";

use Tk;
use Tk::JPEG; # temporary, until we can get yr numbers in as xpm inserts 
use Tk::NoteBook;
use Tk::TreeGraph;
use Character;

# GLOBAL Variables
my $CURRENT_YEAR;
my %WIDGET;

# Game Config
my $Year_Advance = 5;
my $Start_Year = 1300;
my $Start_King_Age = 25;
my $Start_Queen_Age = 20;
my $Start_First_Child_Age = 5;

# Runtime options
my $DISPLAY_SIZE;
my $DEBUG = 0;

# defs
my $TOOLNAME = 'Blood Royale Game Aid';
my %DYNASTY = (
                 'England' => {'characters' => {}, 'events' => []}, 
                 'Germany' => {'characters' => {}, 'events' => []}, 
                 'Italy' => {'characters' => {}, 'events' => []}, 
                 'France' => {'characters' => {}, 'events' => []}, 
                 'Spain' => {'characters' => {}, 'events' => []}, 
              );

# various display sizes for our tool
my $TINY_SIZE   = '800x600';
my $SMALL_SIZE  = '1024x768';
my $NORMAL_SIZE = '1200x1024';
my $LARGE_SIZE  = '1600x1200';

# color defs
my %Color = ( 'yellow' => "#993",
              'liteyellow' => "#998",
              'pink' => "#e88",
              'ash' => "#999999",
              'gold' => "goldenrod",
              'green' => "#6a3",
              'darkgreen' => "#283",
              'liteblue' => "#5588ee",
              'blue' => "#117799",
              'blue2' => "#1188aa",
              'red' => "#c12",
              'litered' => "#a23",
              'grey' => "#bbb",
              'darkgrey' => "#555",
              'offwhite' => "#eee",
              'white' => "#fff",
              'orange' => "darkorange",
              'orange2' => "#ccaa44",
              'black' => "#111"
            );

# Font Defs
my %Font = (
             $TINY_SIZE   => '-fixed-medium-r-normal--10-*-*-*-*-*-*-*',
             $SMALL_SIZE  => '-fixed-medium-r-normal--12-*-*-*-*-*-*-*',
             $NORMAL_SIZE => '-fixed-medium-r-normal--16-*-*-*-*-*-*-*',
             $LARGE_SIZE  => '-fixed-medium-r-normal--20-*-*-*-*-*-*-*'
           );

my %Bold_Font = (
             $TINY_SIZE   => '-times-bold-r-normal--10-*-*-*-*-*-*-*',
             $SMALL_SIZE  => '-times-bold-r-normal--12-*-*-*-*-*-*-*',
             $NORMAL_SIZE => '-times-bold-r-normal--16-*-*-*-*-*-*-*',
             $LARGE_SIZE  => '-times-bold-r-normal--20-*-*-*-*-*-*-*'
           );

my %Big_Bold_Font = (
             $TINY_SIZE   => '-times-bold-r-normal--12-*-*-*-*-*-*-*',
             $SMALL_SIZE  => '-times-bold-r-normal--14-*-*-*-*-*-*-*',
             $NORMAL_SIZE => '-times-bold-r-normal--20-*-*-*-*-*-*-*',
             $LARGE_SIZE  => '-times-bold-r-normal--24-*-*-*-*-*-*-*'
           );


my %FgColor = ( 'Italy' => $Color{black},
                'Spain' => $Color{black},
                'England' => $Color{black},
                'Germany' => $Color{red},
                'France' => $Color{black},
                'Events' => $Color{black},
              );

my %BgColor = ( 'Italy' => $Color{gold},
                'Spain' => $Color{litered},
                'England' => $Color{green},
                'Germany' => $Color{ash},
                'France' => $Color{blue2},
                'Events' => $Color{offwhite},
              );


# program configs
my $baseColor = $Color{'blue'};
my $textFgColor = $Color{'black'};
my $textBgColor = $Color{'blue'}; 

# P R O G R A M   B E G I N S

  $DISPLAY_SIZE = $NORMAL_SIZE; # the default display size

  # Argv loop
  &argv_loop();

  # init gui and key bindings
  &init_gui();
  &init_key_bindings();
  &init_game();

  # main program
  MainLoop;


# S U B R O U T I N E S

sub init_game {

  $CURRENT_YEAR = $Start_Year;

  &init_dynasties();

}

sub find_dynasty_leader {
  my ($dynasty) = @_;

  my $generation = 1;
  while (exists $DYNASTY{$dynasty}->{'characters'}->{$generation})
  {

     foreach my $char (@{$DYNASTY{$dynasty}->{'characters'}->{$generation}})
     {

        next unless $char->alive;

        # NOT strictly right, will pass over queen-mothers
        next if ($char->sex eq 'female' && $char->married);

        return $char;
     }
     $generation++; 
  }

}

sub update_events_display {
  my ($frame) = @_;
  
  $WIDGET{'notebook'}->configure(-bg => $BgColor{'Events'});
  $frame->configure(-bg => $BgColor{'Events'});

}

sub update_display {


   &update_year_display();
#   &update_events_display();

   foreach my $dynasty (keys %DYNASTY) 
   { 
      # insert in tree graph
      &update_dynasty_display($dynasty);
   }
}

sub update_year_display {

  $WIDGET{'year_label'}->configure(-text => $CURRENT_YEAR);

}

sub clear_treegraph_display { 
   my ($widgetname) = @_;

   # if its not been 'raised' yet, then widget may not exist.
   # in this case, we ignore this command
   if (defined $WIDGET{$widgetname}) {
      $WIDGET{$widgetname}->clear();
   }
}

sub print_char_info_box
{
  my ($tg, $char, $king, $screen_pos) = @_;

  my $name = $char->name;
  my $age  = $char->age;
  my $ST = $char->strength;
  my $HT = $char->constitution;
  my $AP = $char->charisma;

  my $line = "$name";
  $line .= " (KING)" if $char == $king; 

  my $ref = ["Name:$line", "Age:$age", "ST:$ST HT:$HT AP:$AP"];

  unless ($char->married)
  {
     push @$ref, "Sex:".$char->sex;
  }

  $tg -> addNode
  (
     nodeId => $name,
     after => $screen_pos,
     text => $ref
  );

}

sub update_dynasty_display {
   my ($dynasty) = @_;

   my $frame = $dynasty . '_text';

   $WIDGET{'notebook'}->configure(-bg => $BgColor{$dynasty});

   return unless defined $WIDGET{$frame};

   &clear_treegraph_display($frame);

   my $king = &find_dynasty_leader ($dynasty);

   my $tg = $WIDGET{$frame}; 
   my @screen_pos = (20,0);
   my $generation = 1;
   while (exists $DYNASTY{$dynasty}->{'characters'}->{$generation}) 
   {

     foreach my $char (@{$DYNASTY{$dynasty}->{'characters'}->{$generation}})
     {

        next unless $char->alive;

        my $married = $char->married;
        next if $married && $char->sex eq 'female';

        # draw the character
        &print_char_info_box($tg, $char, $king, \@screen_pos);

        # draw the (female) spose
        if ($married && $married->alive) 
        {

           $screen_pos[0] += 120;

           my $start_line = $screen_pos[0] - 20;
           my $end_line = $start_line+10;
           $tg->createLine($start_line, $end_line, $start_line+20, $end_line, -fill => 'white', );
           $tg->createLine($start_line, $end_line+5, $start_line+20, $end_line+5, -fill => 'white', );

           &print_char_info_box($tg, $married, $king, \@screen_pos);
        }

        my $father = $char->father;
        if ($father && $father->alive) 
        {
        #   $tg->addDirectArrow( to => $char->name, from => $father->name,);
        }

        # bump up screen position
        $screen_pos[0] += 120;
     }

     $screen_pos[0] = 20;
     $screen_pos[1] += 200;
     $generation++;
   }


 # OR add a node after another one, in this case the widget 
 # will draw the arrow
# $tg->addNode
# (
#    after =>'King',
#    nodeId => 'Child1',
#    text => ['some','text']
#  );

# $tg->addNode
#  (
#     after =>'King',
#     nodeId => 'Child2',
#     text => ['some more','text']
#  );

#$tg -> addDirectArrow( from => 'Child2', to => 'King',);

 $tg->arrowBind
  (
   button => '<1>',
   color => 'orange',
   command =>  sub{my %h = @_;
                   warn "clicked 1 arrow $h{from} -> $h{to}\n";}
  );

 $tg->nodeBind
  (
   button => '<2>',
   color => 'red',
   command => sub {my %h = @_;
                   warn "clicked 2 node $h{nodeId}\n";}
  );

 $tg->command( on => 'arrow', label => 'dummy 2', 
                 command => sub{warn "arrow menu dummy2\n";});

 $tg->arrowBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});

 $tg->command(on => 'node', label => 'dummy 1', 
                 command => sub{ warn "node menu dummy1\n";});

 $tg->nodeBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});


}

sub init_dynasties {
   for (keys %DYNASTY) { &init_dynasty($_); }
}

sub init_dynasty {
   my ($which) = @_;

   my $king = new Character();
   my $queen = new Character();
   my $child = new Character();

   $king->name('King');
   $king->age($Start_King_Age);
   $king->sex('male');
   $king->married($queen);
   $king->generation(1);

   $queen->name('Queen');
   $queen->age($Start_Queen_Age);
   $queen->sex('female');
   $queen->married($king);
   $queen->generation(1);

   $child->name('First Child');
   $child->age($Start_First_Child_Age);
   $child->generation(2);
   $child->father($king);

   # now add them to the dynasty 'roll'
   &add_character_to_dynasty($which, $king);
   &add_character_to_dynasty($which, $queen);
   &add_character_to_dynasty($which, $child);

}

sub add_character_to_dynasty {
   my ($which, $char) = @_;
   my $rank = $char->generation();

   unless (exists $DYNASTY{$which}->{'characters'}->{$rank})
   {
     $DYNASTY{$which}->{'characters'}->{$rank} = [];
   }

   push @{$DYNASTY{$which}->{'characters'}->{$rank}}, $char; 

}

sub init_gui {

  # main frame/WIDGET
  $WIDGET{'main'} = new MainWindow();
  $WIDGET{'main'}->title("$TOOLNAME $VERSION ($DISPLAY_SIZE)");

  # main frames
  my $menu_bar = $WIDGET{'main'}->Frame()
          ->pack(side => 'top', expand => 0, fill => 'x');
  my $bannerFrame = $WIDGET{'main'}->Frame()
          ->pack(expand => 0, fill => 'x');
  my $topFrame = $WIDGET{'main'}->Frame()
          ->pack(expand => 0, fill => 'x');
  my $leftTopFrame = $topFrame->Frame()
          ->pack(side => 'left', expand => 0, fill => 'both');
  my $rightTopFrame = $topFrame->Frame()
          ->pack(side => 'right', expand => 0, fill => 'both');
  my $bottomFrame = $WIDGET{'main'}->Frame()
          ->pack(side => 'bottom', expand => 'yes', fill => 'both');

  # sub-frames

  # configure frames
  $menu_bar->configure( relief => 'raised', bd => 2, bg => $baseColor );
  $bannerFrame->configure( -bg => $baseColor, -fg => 'red', bd => 4 ); 
  $topFrame->configure( relief => 'raised', -bg => $baseColor, bd => 2 ); 
  $leftTopFrame->configure( -bg => $baseColor, bd => 2); 
  $rightTopFrame->configure(-bg => $baseColor, bd => 2); 
  $bottomFrame->configure(-bg => $baseColor, bd => 2); 

  # Menu stuff
  $WIDGET{'menuOptions'} = &create_options_menu($menu_bar);
  $WIDGET{'menuHelp'} = &create_help_menu($menu_bar);

  # Widgets
 
  $WIDGET{'banner_label'} = $bannerFrame->Label( 
                                                 -bg => $baseColor,
                                                 -fg => $Color{'green'} 
                                                )->pack(expand => 0, fill => 'both'); 

  my $banner_image = $WIDGET{'banner_label'}->Photo(-data => &banner_image(), 
                                                     -format => 'xpm');
  $WIDGET{'banner_label'}->configure(-image => $banner_image);

  $WIDGET{'next_turn_button'} = $leftTopFrame->Button( -text => "Next Turn",
                                                   -bg => $Color{'green'},
                                                   -fg => $Color{'black'},
                                                   -command => sub { &next_turn() },
                                                 )->pack( side => 'left', fill => 'both', expand => 0);

  my $thirteenImage = $rightTopFrame->Photo( -format => 'jpeg', -file => "13.jpg");
  my $oneImage = $rightTopFrame->Photo( -format => 'jpeg', -file => "1.jpg");
  my $twoImage = $rightTopFrame->Photo( -format => 'jpeg', -file => "2.jpg");
  $WIDGET{'year_photo'} = $rightTopFrame->Label( -image => $thirteenImage, 
                                                 )->pack( side => 'left', expand => 0);
  $WIDGET{'year_photo1'} = $rightTopFrame->Label( -image => $oneImage, 
                                                 )->pack( side => 'left', expand => 0);
  $WIDGET{'year_photo2'} = $rightTopFrame->Label( -image => $twoImage, 
                                                 )->pack( side => 'left', expand => 0);

  $WIDGET{'year_label'} = $rightTopFrame->Label( -text => $Start_Year,
                                                )->pack( side => 'left', expand => 0);

  # add in buttons
  $WIDGET{'notebook'} = $bottomFrame->NoteBook(
                                                -bg => $BgColor{'Events'},
                                              )->pack(fill => 'both', expand => 1);
  $WIDGET{'notebook'}->add('Events',  -label => 'Events',
                            -createcmd => sub { &make_events_frame($_[0])},
                            -raisecmd => sub { &update_events_display($_[0]); }, 
                          );
  my $image = $WIDGET{'notebook'}->Photo(-data => &italy_image, -format => 'xpm');
  $WIDGET{'notebook'}->add('Italy',  -image => $image,
                            -createcmd => sub { &make_country_frame($_[0], 'Italy')},
                            -raisecmd => sub { &update_dynasty_display('Italy')},
                          );
  $image = $WIDGET{'notebook'}->Photo(-data => &england_image, -format => 'xpm');
  $WIDGET{'notebook'}->add('England',  -image => $image,
                            -createcmd => sub { &make_country_frame($_[0], 'England')},
                            -raisecmd => sub { &update_dynasty_display('England')},
                          );
  $image = $WIDGET{'notebook'}->Photo(-data => &spain_image, -format => 'xpm');
  $WIDGET{'notebook'}->add('Spain',  -image => $image,
                            -createcmd => sub { &make_country_frame($_[0], 'Spain')},
                            -raisecmd => sub { &update_dynasty_display('Spain')},
                          );
  $image = $WIDGET{'notebook'}->Photo(-data => &germany_image, -format => 'xpm');
  $WIDGET{'notebook'}->add('Germany',  -image => $image, 
                            -createcmd => sub { &make_country_frame($_[0], 'Germany')},
                            -raisecmd => sub { &update_dynasty_display('Germany')},
                          );
  $image = $WIDGET{'notebook'}->Photo(-data => &france_image, -format => 'xpm');
  $WIDGET{'notebook'}->add('France',  -image => $image,
                            -createcmd => sub { &make_country_frame($_[0], 'France')},
                            -raisecmd => sub { &update_dynasty_display('France')},
                          );

}

sub make_events_frame {
   my ($frame) = @_;

  $WIDGET{'events_text'} = $frame->Scrolled ('Text',  
                                       -scrollbars => 'ose',
                                     )->pack( fill => 'both', expand => 1 );

  $WIDGET{'events_text'}->configure (
                                font => $Font{$DISPLAY_SIZE},
                                wrap => 'none',
                                state => 'disabled',
                                fg => $FgColor{'Events'},
                                bg => $BgColor{'Events'}, 
                                                     ); 


}

sub make_country_frame {
   my ($frame, $country) = @_;

   my $frame_name = $country . '_text';

   $WIDGET{$frame_name} = $frame->Scrolled('TreeGraph',
                                           -scrollbars => 'se', 
                                             )->pack(fill => 'both', expand => 1); 

   $WIDGET{$frame_name}->configure( fg => $FgColor{$country},
                                    bg => $BgColor{$country},);

}

sub create_options_menu {
  my ($menu_bar) = @_;

  my $menu; 
  $menu= $menu_bar->Menubutton(text => "Options", bg => $baseColor,
                                     -font => $Font{$DISPLAY_SIZE},
                                     -menu => $menu
                                  )->pack(side => 'left');

  $WIDGET{'menu_opt_load'} = $menu->command (-label => 'Load',
                                             -font => $Font{$DISPLAY_SIZE},
                                             -bg => $baseColor,
                                             -command => sub { &load_character(1); }
                                            );

  $menu->separator(fg => $baseColor, bg => $baseColor);

  $WIDGET{'menu_opt_save'} = $menu->command (-label => 'Save',
                                             -font => $Font{$DISPLAY_SIZE},
                                             -bg => $baseColor,
                                            );
                                            # -command => sub { &save_character(0); }

  $WIDGET{'menu_opt_saveas'} = $menu->command(-label => 'Save As',
                                              -font => $Font{$DISPLAY_SIZE},
                                              -bg => $baseColor,
                                             );
                                             #-command => sub { &save_character(1); }

  $menu->separator(fg => $baseColor, bg => $baseColor);

  $WIDGET{'menu_opt_quit'} = $menu->command ( -label => 'Quit',
                                              -font => $Font{$DISPLAY_SIZE},
                                              -bg => $baseColor,
                                              -command => sub { &my_exit; }
                                            );

  return $menu;
}

sub create_help_menu {
  my ($menu_bar) = @_;

  my $menu; 
  $menu= $menu_bar->Menubutton(text => "Help", bg => $baseColor,
                                     -font => $Font{$DISPLAY_SIZE},
                                     -menu => $menu,
                                   )->pack(side => 'right');

  $WIDGET{'menu_help_about'} = $menu->command ( -label => 'About',
                                                -font => $Font{$DISPLAY_SIZE},
                                                -bg => $baseColor,
                                              );
                                              #-command => sub { &my_exit; }


  return $menu;
}

sub init_key_bindings {

  # some generic bindings
  $WIDGET{'main'}->bind( '<Alt-q>' => sub { &my_exit(); } );

}

sub generate_events {
  my ($this_year) = @_;


}

sub next_turn {

   $CURRENT_YEAR += $Year_Advance = 5;

   &generate_events($CURRENT_YEAR);

   &update_display();

}

sub argv_loop {

  while ($_ = shift @ARGV) {
    # print $_, "\n";
    if(/-help/) 
    { 
       print STDERR "NO help available for $0 currently, sorry \n"; 
       &my_exit(-1);
    }
    elsif(/-v/) 
    { 
       $DEBUG = 1; 
    }
    else 
    { 
       print STDERR "Unknown command line option: '$_'\n";
       print STDERR "Use '-help' to get a list of valid options.\n"; 
       &my_exit(-1);
    }
  }

  sub my_exit {
     my ($signal) = @_;
     $signal = 0 unless defined $signal;
     exit $signal;
  }
}

sub randomD6 {
  return &random(1,6);
}

sub random {
  my ($max_value, $min_value) = @_;
  my $value = int (rand ($max_value)) + $min_value;
  return $value;
}

sub italy_image {
  my $buf = '/* XPM */
static char *Italy[] = {
/* width height num_colors chars_per_pixel */
"    74    40      256            2",
/* colors */
".. c #0b0706",
".# c #1f8523",
".a c #938823",
".b c #910b14",
".c c #9ec625",
".d c #8f8994",
".e c #104812",
".f c #8e4916",
".g c #95c6b3",
".h c #514819",
".i c #71b536",
".j c #cc8825",
".k c #1687b1",
".l c #d3c899",
".m c #ce472d",
".n c #ce898e",
".o c #4d5786",
".p c #cb111c",
".q c #115c9c",
".r c #93a62a",
".s c #cfa82c",
".t c #d6e6a6",
".u c #926f17",
".v c #4f0609",
".w c #4f681c",
".x c #518da8",
".y c #4f8a26",
".z c #146719",
".A c #8ea9b0",
".B c #91281a",
".C c #539e2d",
".D c #d4c632",
".E c #55a1a7",
".F c #b6e5b1",
".G c #8e6971",
".H c #92895b",
".I c #d7e56b",
".J c #cfa95f",
".K c #8dabcd",
".L c #c9cadb",
".M c #72681d",
".N c #ca6922",
".O c #502811",
".P c #95c7da",
".Q c #cc8a58",
".R c #cfe7ec",
".S c #0e280d",
".T c #93a864",
".U c #704814",
".V c #156954",
".W c #d4c767",
".X c #af7218",
".Y c #cd2725",
".Z c #508c5d",
".0 c #914a5e",
".1 c #11484f",
".2 c #cfaa90",
".3 c #53a2d6",
".4 c #943655",
".5 c #ae0d19",
".6 c #ad491f",
".7 c #52b5b3",
".8 c #d06866",
".9 c #6f90a2",
"#. c #ccaaca",
"## c #b02725",
"#a c #6f280f",
"#b c #ecc998",
"#c c #afa99d",
"#d c #eaa95e",
"#e c #153759",
"#f c #b08958",
"#g c #b18824",
"#h c #afc9d9",
"#i c #edc866",
"#j c #2d4817",
"#k c #b4a861",
"#l c #2e681a",
"#m c #ebe8e2",
"#n c #2e2814",
"#o c #53a061",
"#p c #51685b",
"#q c #b1958f",
"#r c #f0895d",
"#s c #716955",
"#t c #77b6ba",
"#u c #eaa92e",
"#v c #ecaa91",
"#w c #aaabcf",
"#x c #379fa6",
"#y c #ebcbce",
"#z c #504951",
"#A c #e98a26",
"#B c #cd2748",
"#C c #79ccc4",
"#D c #6e494f",
"#E c #907244",
"#F c #1373a8",
"#G c #af7543",
"#H c #708c5f",
"#I c #b0c7b0",
"#J c #f2e6a5",
"#K c #f36838",
"#L c #708b24",
"#M c #e80b22",
"#N c #72060c",
"#O c #18855b",
"#P c #cc4859",
"#Q c #50748e",
"#R c #2f76aa",
"#S c #b3a72c",
"#T c #73a7d0",
"#U c #75b9da",
"#V c #306956",
"#W c #b01339",
"#X c #1789ce",
"#Y c #2f0607",
"#Z c #ec2828",
"#0 c #75a5af",
"#1 c #8f5819",
"#2 c #71a262",
"#3 c #6f748d",
"#4 c #4f90d0",
"#5 c #941038",
"#6 c #4f3746",
"#7 c #edc732",
"#8 c #cb143c",
"#9 c #ad591a",
"a. c #8c9bcd",
"a# c #94c66a",
"aa c #99e5ed",
"ab c #5eb56a",
"ac c #f28788",
"ad c #efe544",
"ae c #b6c668",
"af c #b06870",
"ag c #34885b",
"ah c #af485f",
"ai c #f16860",
"aj c #f04930",
"ak c #324753",
"al c #af2951",
"am c #eabac8",
"an c #323656",
"ao c #e93348",
"ap c #ef5354",
"aq c #b6e5ec",
"ar c #359fd9",
"as c #6f5886",
"at c #6e3750",
"au c #325b95",
"av c #399827",
"aw c #bcda31",
"ax c #4a79c1",
"ay c #4fb6e4",
"az c #2f79cb",
"aA c #328aae",
"aB c #70a12b",
"aC c #328dcf",
"aD c #7cc978",
"aE c #d49ecc",
"aF c #6c7bc1",
"aG c #f2e670",
"aH c #6c92cd",
"aI c #ab9ac1",
"aJ c #b3da75",
"aK c #1377c5",
"aL c #907976",
"aM c #71170f",
"aN c #358725",
"aO c #b7c72e",
"aP c #37995d",
"aQ c #cb7926",
"aR c #905960",
"aS c #cc7a67",
"aT c #ef7934",
"aU c #eb1926",
"aV c #f37964",
"aW c #78cde8",
"aX c #cc5926",
"aY c #4f180e",
"aZ c #8f3817",
"a0 c #0f380f",
"a1 c #af3822",
"a2 c #2e3818",
"a3 c #2e180f",
"a4 c #ae7972",
"a5 c #af5965",
"a6 c #f25837",
"a7 c #0d180a",
"a8 c #939726",
"a9 c #8d9aa4",
"b. c #115815",
"b# c #97d4b0",
"ba c #50581b",
"bb c #ce9829",
"bc c #d5d7a1",
"bd c #92b52a",
"be c #d1b72f",
"bf c #4e781f",
"bg c #16761b",
"bh c #91b7b3",
"bi c #d5d432",
"bj c #939860",
"bk c #d1b864",
"bl c #91b9d2",
"bm c #ccd9e3",
"bn c #717820",
"bo c #98d6e4",
"bp c #ce995c",
"bq c #d2f4f3",
"br c #92b769",
"bs c #725818",
"bt c #167757",
"bu c #d6d66a",
"bv c #cf3826",
"bw c #135a54",
"bx c #d0b994",
"by c #c9bbd4",
"bz c #6f3912",
"bA c #eed89e",
"bB c #aeb9a9",
"bC c #ebb963",
"bD c #b1995c",
"bE c #b29728",
"bF c #b3d7e3",
"bG c #efd76b",
"bH c #2d5818",
"bI c #b5b765",
"bJ c #307720",
"bK c #f2f8dc",
"bL c #ed995e",
"bM c #ecb82f",
"bN c #ecba93",
"bO c #abbad2",
"bP c #ebdad8",
"bQ c #e99929",
"bR c #cc374f",
"bS c #b3d6b2",
"bT c #fafbaa",
"bU c #d0585c",
"bV c #b5b62e",
"bW c #327858",
"bX c #ef372b",
"bY c #efd633",
"bZ c #ee9a90",
"b0 c #315856",
"b1 c #ae3853",
"b2 c #b8f4f3",
"b3 c #75b670",
"b4 c #ce9a8e",
"b5 c #513814",
"b6 c #4f795b",
"b7 c #71785a",
"b8 c #505855",
"b9 c #705952",
/* pixels */
"azaz#4.P#hbFbFbFbF#h#hbF#h#h.Kbl#hbF#h.P.P#hbF#h#hbF#h#hbO.P#hbF#h#h#h#hbFbFbF#hbl#T#h#hbl.3#Tbl#TazaKaCaC#4aCaAaC#Tbl.P#h#hbF#hbF.3.3#hbF#T#TbobF.3",
"#XaA#T.PbFbF#h#hbF#h#h#h#hbFbl#T#h#h#h#T#T#h#h#hbF#h#h#h#h#h#h#h#h#h#hbF#h#h#h.P#U#T.P.P#T.3#T#U.3#4aC#4aAaCaAaz#4#T.P#h#hbF#h#h#U#T#T#T#T#T#T#T#T#T",
".3#TblbFbF#hbF#hbF#h.g#h#h.P#T#T#T.P#U#T#T#T.P#h#h#hbF#hbF#h#h#h#h#hbF#h#h.P.Pbl#T#T#T#Tbl.Pbl#U#T#U#U#U#U.3axaA.3bl#hbF#h#h.P#UbO.P#hbl.P.P.P.Pbl.P",
"#hbo#hbF#h#hbF#h#h.g#h#I.P.Pblbl.Pblblblbl#h.P#hbo#h.P.P#h.P#h#hbF#hbF#h#h.Pblbl.Pblbl.Pbl.P.P#h#h#h.P#h.P.Pbl#Ubl#h#h#hbF#h#h#hbFbFbF#h#h#h#h#hbo#h",
"bF#hbFbF#hbmbF#h#h.g#h#h#h#h#hbF#h#h.PbObF.P#h#hbF#h#hbF#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h.P#h.P#h#h#h#h#h#h#h#h#h#h#hbFbmbF#h#hbF#hbFbFbF#hbF#h",
"#hbFbF#hbF#hbF#h#h#I#h#h#h#h#h#h#h#h#hbF#h#hbF#hbF#h#h#h#h#hbF#h#h#h#h#h.P#h#h#h#h#hbF.P#h#h#h#h.P#h#h#h#h#hbF#h#h#h#h#hbF#hbF#hbmbFbF#hbFbF#h#h#h#h",
"#h#hbFbF#IaLbD#q#kbDbDbja4bj.HbDbD#kbjbDbDbja4bja4bj#qbjbDbjaL.T.dbB#h#hbF#h#h#h#h.P#h#h#hbF#h#h#h#h#h#hbF#h#h#h#h#h#h#h#hbF#h#hbF#h#hbmbF#hbmbF#hbm",
"bFbF#hbFblbx.l#k.2bcbcbcbAbcbAbcbPbcbAbcbcbcbAbc.l.l#i.l.lbcbAbcbx.dbF#h#Ibo#hbF#hbF#hbF#h#hbFbF#h#h#hbF#h#h#h#h#h#h#hbFbF#hbmbF#hbmbF#hbF.LbFbF#h#h",
"bF#h#h#h#hbx#E.v.B.4aR#Gafb4.lbAbcbcbc#bbcbcbcbA.l#bbcbAbc.lbcbAbc.dbF#hbF#h#h#hbF#h#h#hbFbFbF#h#h#h#hbh.A.Aa9#3b7#s#s#cbFbFbF#h#h#h#hbmbFbF#hbFbFbF",
"bFbF#hbFbObxbA#f.B#G#f#DaM.b#GbAbA.l.lbxbx.l#bbxaebI#H.W#i#b#k.lbc#s.A.Abh#hbF#hbF#hbF#hbF#h.gbha9.d.H.u#E.u#gbE.Jbb#g#nb9b7aL.T#q.d#H.d#hbFbm#hbFbF",
"#hbF#hbFbObx.lbcbx.JaS#G.J#N#Dbx.Tbj.wbW.y#2b6bJbHa2bn#kbI.Tb9bu.la7..a3#1.Ua2.hb9#sb7b7.HbD#G#f#S.s.s.J.Jbk.Jbx.J.JbDb5#g#gbb#g#g.u#g#E.M#h#hbmbF#h",
"#hbFbF#h#Ibx.lbA.l.B#N.b.6aMaY.ab.b.bH.e#na0bJbJ#V.zbf#2b6ak#g.W#ia7#Y#1bEbpbEbpbEbEbb.sbbbebebe.Jbe.Jbk.l.l.l.lbxbxbkbbbbbb.Jbb#g.X.u.XbD#I.LbF#h#h",
"#h#h#hbF#h#kbA.l#b#a.b#NaM#N.baMaY.MbHbH#l#lb.#j#obW.Sa7a7.M#b.W.Wa7a3.Xbb.s.Jbe.Jbe.Jbe.J.Jbkbkbkbkbkbxbxbx.l.lbxbxbk.JbD.Jbx.Jbb#f.j.sbk.LbF#hbFbF",
".P#hbF#hbF#k#bbAbx.B.p.5#N.v.b.b#NaL.h#s.wbHa2.S#lagb..ebH#k#H.a#ia3.O.ubEbE.Jbe.sbkbebkbkbkbkbkbkbxbxbxbx.l.lbN.lbxbpbDbkbDbkbk.2.JbEbb.2#hbS.L#hbF",
"#T#T.PbObF#q.lbA#b.J.B.b#9.B.5#N.v.O.Oa3#D.f.ha0a7bHbH.e.SbHbHbk.Wa7.O.X#g#gbUah#Pah#PbU.6bkbkbx.Wbxbk.l.Wb4aSaSbxbkbk.Jbxbkbxbkbkbk.J.sbx#hbFbFbF.L",
"bF#h#h#h#h#cbAbcbc#b#kaS.J.5.5.b.va3a3.v#Y#Y..a2a7a0.za7a0a0#p#Lbk..bz.X#g.Q#GaS#bbT#JaSa5bN.Q.Qbkbxbk#b#bahbNbpaSbk.Jbxbkbx#ibk#ibk.J.Jbx#hbF#hbmbF",
"bF#h#hbFbF#k.lbG#bbc#b.lbD.b#N#N.v#D.hb9#Dbsb8.SbJbJbJ.Sa7.Sa2bD.W...f.Xbbbb.JbbaSbTbx#GbkaSbLa5bkbxbNbk#baS#b#b.8.J.J.2bp.J#b.Wbk#ibebk#hbS.Lbm#hbm",
"#h#hbF#h#h#cbAbx#EbkbA.lbp#N#Ebk#Gbj#p#sb7#pa0.w.Wa8bW.e..a0.ybI#Sa3#1bDbb.s.J.JaSbT.l#Gbp.8bTbUahaX.8aSa5#GbN.l##aSaS##aS#PbN#i#ibkbCbI.LbFbFbFbmbF",
"#h#hbFbF#h#q.lbxaZ.6#G.8.6.v.J.laBbfbnbnbHbHbnbVbj.r.Za0...Sa0.a.Ha3.XbDbpbD.J.s.8bTbkaS.8.JbTaSb1#Jb1#dbA#W#vbA#5bN#J#5aSbU.l.W#ibCbkbx#hbFbmbF#hbm",
"#h#hbF#hbFbB.laXaM.4.BaY#NaM#kbI.l.HbIbxbkbk#kbjb7.CbW.Sa7a0bfbk.a.O.XbEbE.j#k.saSbT.2aSbx.8bTahahbxa1#v#J##.2#J.6bUbTbUaS.J#b#i.lbMbkbxbF#hbFbmbm#h",
"bF#hbF#h#h#h.JaS#fbcbcbxbn#kb8#H.wbH#H.w#2b7.y.wbH.Zb..S#nb.#j#Sb9#a.u.X#fbEbpbk.8bTbkaS.l.8bTbUaS.8.2.JbT#W.2#JaXbUbA#J.8.l#bbu#i#ibkbIbF#hbF#hbFbm",
"bFbF#hbFbF#hbjbAbcbAbI.T#pbj#H#H#o.Z.ybW.ybWbWaN#V.ea7a7#jbH#Sbkb5bz#1#G#gbDbk.Q.QbTbx.m.JbUbTah.mbT.8aSbTa1bL.t.6bpaS#J#GbkbC#i.WbN.W.2#hbm#hbF#h#h",
"#hbFbF#h#h#h#c#bbAbc.H#l#H#la7a7a0b.a0.e.e.S.S.Sa7a7.S#j#j.hbk.Wa3.f.u.a#g.JaSaSbN#bbx.2bUa1#JbA.8.tbAbp#Jaf#v#bb1#9a1b4.QbC.W#ibkbe.J.T#hbmbF#hbmbF",
"bF#h#hbF#h#hbB.l.lbA#Ha2#2.Sa0bH#jbH.y#na0a7a7.Sa0bHbH#nbfbk.l#Sa3.f.u#G.X#kbp#GaX#G.QaX.8.6bUa5.QbUbUaSa5aS.8#G###v.ma5.J.J.J.Jbk.J.abB#h#h#hbm#h#h",
"#h#hbF#h#hbF#hbDbA.l.T.w#2#nbH.MbfbHbWb0a7.e#n..#j#nbH.abk.l#b#saY#1#1.a#G.Jbx.Jbkbkbkbkbpbxbk.W.l.W.l.WbxbkbxbkaXbcbp.6.jbbbb.s.JbE.U.d#hbmbF#hbSbm",
"#h#hbFbF#h#h#h#qbcbA#s#l#j#Hb0#lbHbHbfbJa2#lbababE.Wbk.W.l.l.la3bz.U#1.u#f.J.J.J.J.J.JbkbkbCbkbkbN#i.l#bbxbxbkbkb4#G#G#G.X#g.j.j.j.j.sba#IbF#h#hbF#h",
"bF#h#h#h#hbFbF.g.J.l.lb7#ja2#V#2#H#o.Z.Z.Z.Z.ZbHa0.J.lbc.l.lbja7#1bs#1#Gbp.J.J.J.J.Jbkbkbkbxbebkbxbkbxbkbxbkbkbx.J.Jbk.s.jbb.u.f.u.X#g#E.d#h#hbmbF#h",
"#h#h#h#h#h#h#h#hbDbc#b.lbrbHa7a7.S.Sa0.Sa0a0bH.ZbHbabx.l.lbka2#a#1.f.u#g#gbE.JbbbE.s.J.Jbkbk.J.Jbkbxbkbp#kbkbx.Jbkbkbp.sbb.sbbbs.fbsaQ.uaL#hbF#hbmbF",
".P#h#h#h#h#h#h#hbO.Jbc.lbDb7#k#l.w.H#Lbn.wa0a7bJbHa2bV.l.l#fa3.Ubz#1.X#f#gbbbDbbbb#f.Jbk.JbkbbbEbbbDbpbbbp.Jbkbk.J.J.Jbp.sbb.j#1#1#1.abs.g#h#h#h#hbm",
"#h#h#h#h#h#h#hbF#haLbc#bbc.W.lbx.WbIbx#ka8#l.ebW#j#j#kbx.Ja2bz.Ubs#E#E#E#EbD#f#E#E.U.2bkbkbk.J.sbpbbbp#k#fbD.J#qbj#q#k#qbjbj#q#q#cbBbBbO#h#h#h#hbm#h",
"#h#hbF#hbF#h#h#h#hbhb4.l.l#b.l#La2.e.eb..VbWb0.S.S.wbIbx#E.gbhbO#h#h#h#I#h#h#hbhbha9.Ta9#cbjaL.H#E#E.Hbjbh#I#h#h#h#h#h#h#h#hbF#h#hbF#h#h.LbFbm#hbSbF",
"bF#h#h#h#h#h#h#h#h#Ia9bxbcbubI#jb.b0#j.ea2a0a0a0#j.J.Wbj#c.gbObO.P#h.g#hbO#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#h#hbF#h#h#h#hbF#hbF#hbF#h#h",
"#h#h#h#hbF#h#h#h#h#h#hbj.l#bbx.ebJa0a0bH#Lbna8#SbkbxbD.d.gbO#I.P#I#h#hbObF#h#h#h#h#h#hbO#h#h#h#h#h#h#h#h#h#hbO#h#h#h#h#h#hbF#h#h#hbF#h#h#hbF#h#h#h#h",
"#h#h#h.P#h#h#h#h#h#h#hbh.HbAbc#k#jbHa0.w.Jbk.lbx.W#kbj.P.gbh.PbO.PbO.P.P.P#I#h#h#h#h#h#h.P#h#hbO#h#h.P#Ibo#h#h#h#h.P#h#h#h#h#h#h#h#hbFbF#h#h#hbS#h#h",
"#h#h#h#h#h#h#h#h#h#h#hbObObD.l.lbIbH.e#jbV.W.l.lbIbjbl#hbO.P#I.P#h#I.P#hbO#h#h#h.P.P#h#h#h#h#h#h.P#h#hbO#h#h.P#h#h#h#hbO#h#h#h#h#h#h#h#h#hbFbF#h#h#h",
"bO.P#h#h.PbObF.P#h.P#h#h#h.AbDbc#b#p.ebabk.W.WbI.HbO#I.P#I.P#h#h#h.P#h#h#h#h#h#h#h#h#h.P#h#h#h#h#h.P.P#h#h#h#h#h#h#h#hbF.P#hbF#h#h#h#h#h#h#h#hbF#h#h",
"bO#h#h#h.P#h#h#h#h#h#h#h#h#h#c#k.lb7.ebk#i.W.J.d.P.PbO.PbO#h#h#h#h#hbO#h.P#h#h#I.P#h#h#h#h#h#h#h#h#h#h.P#h#h#h#h#h#h#h#h#h#h#h#h#I#hbF#h#hbF#h#h#h#h",
"#h#h.P#h#h#h#h#h#h#h.P#h#h#h#I.A#kbIbabk.W#f#c.g#IbO.P#h#h#h#h#h#h#h#h#h#I.P#h.P#h#h#h#h#h#hbF#h#hbF#h#h#h#h.P#h#h#h#h#h#h#h#hbF#hbF#h#hbF#hbF#hbFbF",
"bO#h#h.PbObF.P#h.P#I#h#h#h#h#h#h.AbD#k#Sbj.g#hbO#h.P#I.P#h#h#h#h#h#h#h.P#h#h#h#IbobO#h#h#h#h#h#h#h#h#h#h#h.P#h#h#h#hbF#h#h#hbF#h#h#h#h#h#h#h#h#h#h#h",
"#h#h#h#h#h#h#h#h.P#h#h.g#I#h#I#h#h.g#qa9#h#h#h#h#h#hbO#h#h#h#h#h#h#h#h#h#h#h#h#h.P#h#h#h.P#h#h#h#h#h#h.P#h#h#h#h#h#hbF#h#h#h#h#h#h#h#h#hbSbF#h#hbS#h"
};';
   return $buf;
} 

sub germany_image {
  my $buf = '/* XPM */
static char *Germany[] = {
/* width height num_colors chars_per_pixel */
"    80    41      251            2",
/* colors */
".. c #1d0a10",
".# c #aa851c",
".a c #ecc42a",
".b c #d08818",
".c c #d1c28e",
".d c #cb2b1d",
".e c #cfa41a",
".f c #ece297",
".g c #d4a27c",
".h c #444234",
".i c #ecc48c",
".j c #945624",
".k c #d8b21c",
".l c #c1a534",
".m c #cc5f4f",
".n c #ebe5be",
".o c #d0856b",
".p c #f6d73f",
".q c #bf8419",
".r c #f2d48e",
".s c #33271f",
".t c #96701c",
".u c #7c5f24",
".v c #d2b580",
".w c #d4a44a",
".x c #e9b31b",
".y c #e4c654",
".z c #f0d9b0",
".A c #d8d29c",
".B c #bc8264",
".C c #f6f2c8",
".D c #e4b66c",
".E c #fc8a74",
".F c #784418",
".G c #d49268",
".H c #b47818",
".I c #e8b456",
".J c #291816",
".K c #f3eeb4",
".L c #f3dc90",
".M c #503217",
".N c #e6ce76",
".O c #ce9816",
".P c #bf951a",
".Q c #b6a47c",
".R c #e0c48d",
".S c #fc3e24",
".T c #e5ad4f",
".U c #b94144",
".V c #e5a315",
".W c #f4e397",
".X c #cc7464",
".Y c #947250",
".Z c #f4e5c1",
".0 c #eab79a",
".1 c #b45634",
".2 c #98845c",
".3 c #f3d865",
".4 c #947d29",
".5 c #d2ab5c",
".6 c #eec368",
".7 c #6f531f",
".8 c #896f21",
".9 c #df956c",
"#. c #3f1f14",
"## c #ce9740",
"#a c #d18b72",
"#b c #b98537",
"#c c #ccb28c",
"#d c #f8f3d9",
"#e c #62451a",
"#f c #d7d2ac",
"#g c #291e18",
"#h c #c2b58a",
"#i c #eccba9",
"#j c #eabb24",
"#k c #ebbb61",
"#l c #fcce20",
"#m c #e6bd73",
"#n c #dfcca9",
"#o c #f2ca75",
"#p c #d8a339",
"#q c #eecd8f",
"#r c #f0d59f",
"#s c #44381c",
"#t c #f1deb4",
"#u c #fcda96",
"#v c #513c22",
"#w c #b74d4d",
"#x c #f5e4ae",
"#y c #f4de64",
"#z c #dea57f",
"#A c #b8945a",
"#B c #f4c51e",
"#C c #ccb644",
"#D c #846640",
"#E c #f4edc1",
"#F c #644f1c",
"#G c #c36f59",
"#H c #f3dca0",
"#I c #cc7a60",
"#J c #c36558",
"#K c #8a541c",
"#L c #dc8b6b",
"#M c #e1dbaa",
"#N c #a87118",
"#O c #dca449",
"#P c #c0ab7d",
"#Q c #ba8b40",
"#R c #f4be74",
"#S c #dca28c",
"#T c #b99d69",
"#U c #221012",
"#V c #d2cba2",
"#W c #fc6234",
"#X c #3f2a19",
"#Y c #876519",
"#Z c #d2937c",
"#0 c #f4b44c",
"#1 c #e3cd8e",
"#2 c #ac924c",
"#3 c #edc578",
"#4 c #dc9c38",
"#5 c #fcfae4",
"#6 c #e4bb8a",
"#7 c #f5eab3",
"#8 c #daab18",
"#9 c #ccba80",
"a. c #b63740",
"a# c #ac922c",
"aa c #9c6919",
"ab c #a77e41",
"ac c #cc4e34",
"ad c #cc8c44",
"ae c #cc341c",
"af c #cc6d5f",
"ag c #705844",
"ah c #a58b5c",
"ai c #a77c1c",
"aj c #ecd24c",
"ak c #5f3d15",
"al c #d0ba54",
"am c #a08438",
"an c #7c7644",
"ao c #e4a83a",
"ap c #c4beac",
"aq c #de9a15",
"ar c #c49541",
"as c #5c4632",
"at c #d2bc90",
"au c #c47e20",
"av c #c4574f",
"aw c #eceabd",
"ax c #e4de9c",
"ay c #df9d7b",
"az c #b49e54",
"aA c #e7c748",
"aB c #ece6b0",
"aC c #e2c474",
"aD c #a9956c",
"aE c #986731",
"aF c #ba8d1c",
"aG c #714c17",
"aH c #bc8a4c",
"aI c #f4b618",
"aJ c #f4d068",
"aK c #dcb44c",
"aL c #dcbe44",
"aM c #c43e2c",
"aN c #7c5519",
"aO c #c4a35c",
"aP c #d08f19",
"aQ c #d09e58",
"aR c #e0ab78",
"aS c #54442a",
"aT c #d8b83c",
"aU c #bcaa4c",
"aV c #b67b32",
"aW c #e4bab4",
"aX c #bc5954",
"aY c #a67431",
"aZ c #896631",
"a0 c #d1ae71",
"a1 c #78682c",
"a2 c #daae32",
"a3 c #e1ad99",
"a4 c #d49c7a",
"a5 c #dcb571",
"a6 c #c4a674",
"a7 c #dcac58",
"a8 c #dcb498",
"a9 c #f4be1e",
"b. c #dcbc78",
"b# c #dc6a4c",
"ba c #fcf2b2",
"bb c #8c733c",
"bc c #343224",
"bd c #ebad18",
"be c #443d2e",
"bf c #fc6e44",
"bg c #d0c3a0",
"bh c #f4da50",
"bi c #d1a45f",
"bj c #e4b32f",
"bk c #e6b387",
"bl c #341916",
"bm c #f3d878",
"bn c #e4d4b0",
"bo c #342018",
"bp c #7c625c",
"bq c #f4eed5",
"br c #c47068",
"bs c #d07b6d",
"bt c #c48b36",
"bu c #2c1211",
"bv c #c4524c",
"bw c #ac7c34",
"bx c #ac8444",
"by c #dcbe8c",
"bz c #c49b51",
"bA c #c09a1e",
"bB c #d49e41",
"bC c #644a1c",
"bD c #ba5252",
"bE c #f5ca21",
"bF c #c46a59",
"bG c #b4aa60",
"bH c #e4d294",
"bI c #dca317",
"bJ c #c48639",
"bK c #f4be5c",
"bL c #c49454",
"bM c #f4e079",
"bN c #645234",
"bO c #7c5a44",
"bP c #eceed8",
"bQ c #bc8e6c",
"bR c #f4cf79",
"bS c #dcb364",
"bT c #dcbd64",
"bU c #cc6657",
"bV c #cc9239",
"bW c #9c5e14",
"bX c #dcba2c",
"bY c #9c7614",
"bZ c #bc7e1c",
"b0 c #e9be96",
"b1 c #745a24",
"b2 c #c4ba8c",
"b3 c #875a19",
"b4 c #a4761c",
/* pixels */
".Z.C.C.C.C.C.C.C.C.C.C.C.C#E#Eaw#E.K.K.K#7#E.Kaeac#7#E.K#E.K.KaB.K#7.C#E#Eaw#E.C#7.Cbqbqbqbq#d#d#d.C.C#d.C#d.C#d.Cbq#E.Cbq.C#d.C#d#d#d.C#d#d#d#d#d#d#d#5#d#d#d#d",
".C.C.Cba.C.C.C.C.C#E.Cba.C#E.C.K.K.Kawaw#7.K#taeb##7aw.K#E#7#7aBaw.K.C#E#E#Eaw#7bq#E#d.C.C#d#d#d.C#d.C#d.C#d#d.C.Cbq#E#E#E#d.C#d.C#d.C#d#d.C#d.C#d#dbq#d#d#d#d#d",
"#5ba.C.C.C.C.C.C.C.C.C.C#E#7#E#Eaw.KaB#7.Kaw.i.d.9aw#7#E.K#7aB#7#7#E.C#E.C#Eaw#E#E#E.C#d#dbP.C#d.C.C#d#d#d.C#d.C#d.C.C#E.Cbq.C#d#d.Cbq.C#d#d.C#d#d#d#d#d#dbP#dbP",
"ba.C.C.C.C.C.C.C.C.C.C#E.C#E.K#E#7#E.K.Kaw.K#L.d.0#7#7.Kaw.KaBaB.Kaw.C#Eaw#7.C#E#Eaw.C#d#d.C#d.C.C#d#d.C#d#d#d#d.C#d#d.Cbq.Cbqbq.C#d#Ebq#d.C#d#d#d#d#dbq#d#dbPbq",
".C#5.C.C.C.C.C#M.n#M#M#M#M.Ab2b2#h#PbG.Qa6a6bQ.B#P#Vaw#7#E#E.KaB#7#E#E#E#E#E#E#Eawbq.C#d#d.CbPbP.CbP.C#d.C#d.C.C#d#d#d.Cbq#d#E.C.Cbqbq#E#d#d.C#d#d#d#d#d#d#d#d#d",
"ba#5.C#5.C.C#f.yaz.NbH.L#1.NbH.Laj.3ajbEbE#B#l#B#ja2.n#E.C.KawawaBaw#E.Kaw#Eawbq#7#E.C#d#d#d.C.C.C.C#d.C.C.C#d.C#d.C#d#d.Cbq.Cbqbq.C.C.Cbq.C#d#d#d#d#d#dbq#dbq#d",
".C.Cba.C.C.C.n#y.2an#C#CbmaxbMaA.4.lbXbE#B#BbE#jaN#j.n#E#Eaw.K#7.K#7#E#E.Kaw.C#Eaw.C#d#d.C.C#d.C#d#d.Cbq#E#E.C.C#d#d.C.C#d.Cbq#E.C.Cbqbq.Cbqbq.C#d#d#dbq#d#d#d#d",
".C.C.C.C.C.CaB.3aCbNbc.h.8a#aAbC#g#g#8bE#B.e.8.M.#bjaB#E.C#E#7aw#E#E.C#E#EaBbqbqaw.nbP#d#dbP#d#Ebq.C#E#E#Ebqbq.C.C#d#d.Cbq#d.C.Cbq.Cbqbq.C#d.C#d#d#d#d#dbq#5#d#d",
".C.Kba.C#EbaaB.aa1bGaS#gbc.haUaz#X#g.k.e#F#X#gaN.#bjaBaw#Eaw#V#Vbg#M.n#E#E#E.naDbxa0#1#t#Vbg.c#9#T#Tatawbq#E.C.Cbq#d#d.C.C.C#Ebq.Cbq.C.Cbq#Ebq#d#d#d#dbq#d#d#d#d",
"#E.K.C#E#E.C#M.3aS#X#g#g#g.sbGbb.J#v.kaG.Jbube.7.7bd.n#Eba.2.w#1.r#rbHaC#f#Eahar#m#r#t.Z.Z#r#q#q.Ia7bibi#h#nap#h#n.zbn#nbgata8.Qbgbn.Cbqbqbqbq#d#d#d#d#d#d#d#d#5",
"#7.C.K.K.C.CaBbm#1aD.s.s.Jagaxal#Uboa9aa#g.J.J#X#8#j.n#7.naE.5.L.W.L.L.r#A#D#bbS#1#r#Ebqbqbq#t#q#o.D.IbzaVaE#bbLbS#maQ###ObBbB##bB#QaO#1.Z.C#d#dbq#d#dbPbPbP#d#d",
"bf#H.C#E.K#EaxaLasaS.s#g.s.N.fam.Jbo.eaIak#Ubo.#bA#j.naw#MbY#m#x#xbM.3.r.5aEbB#OaC.Zbqbq#d.ZaB.r#1#3aLarbJbia5aC#m#o.NbR.N.6.D#O#Obt#bbtara6a0a6.v.va6#TaQbi.n#d",
".E.Zba#E.K#Eax.Lbp#gbo#g#g.#.4.l..aS.8.k#s..#Ubl#e#j.n#7bgaY#qaB#x.WbMbm.Dbw##a7#q.Z#d.C.Z#x#t.L#q#3a7##.wbS#m#3.N.3bm#ubM#rbR#ka7bBbVao#p#4#pbB.w#Oa7#k#3#3.z#d",
"#x#E.K#E.K.C.faC#M.Qbe.J#U.J#g#s#U.J.Jbo.....Jb3.O#j.n#7.Qbw#q.Z#x.W#ubR.wbwbJbF.B#n#Z#t#t#H#x#x#r#q.I.T.D#m.DbR.3#u.L#H.W#x#r#q.6.TbV.T.Ia7.IaC#qbRbR.L.r#rbn#d",
"#E#E.C.K.K.K.fan#v.s#g.J.J#U#g.J#U..#U#U....bu.8a9#j.Zawah#Q#r#x#7.LbMaJ##.1#Lay#abs.o#n.z#H.f#E#H#H#3.I#3.r#o.L#ubm.L#x.Z#x#H.r.r#3#pa7aL#k#R#H#H#H.f.L.L#r.z#d",
"#W#x.Kaw.K.Kax.R#D.8.P.s#U.J#g#g#U..#U#U..ak.Mbl#va2#Eawbb#Q.z#7.W.L.3aJada3#n.o#S.0#Z.Z#x#t#t#7#x.L.r#mbR.L.r.W.L.L#H#x.Z#x#H#H#q#o.I.I.I.6.r.L#H#H.L#H#q#1.zbq",
".S.z.K#E#E.Kax.faBbnaS#v#v#U#U#U....#U..#U.JaiaGaGbj.ZawaZbz.n.Z#u.Wbm.6#Iba#L.gbr.X#Zbqa3.X#a#a#G#G#GbU#J.X#I.X#I#q#I#I.X#Z#I#J.X#J#JafavbF#k.r#H#H.L.r#3#m#r#d",
".z#7.K#E.K#7aB.W.cbN.M#8.M#vbC......bo.J.M#..M.ea9a2#7.AaZa5.Z.Z.W.rbm.6.9ba#J.Xb0#u#abn#aa4.0#Jba.i.R.i#q#q#qbk#x.U#qbF#7.U#u.R#qaybk.R.U.G.6.r#r.z.L#qb.#3bn#d",
"#E.C.K#E.K#Eax.N#v#vaT.P#eaAak......ak.q.J#Nbl.M.Pbj.n#PaY#1.Z#u.L.3aJa7aybaaXbkbF.C#Z#Z#u#w#raXba#JbF#Saybr#ta.ba#w#ra.ba#wb0#a#a#6bF.Wav.oaj.N#H.z#r#o#m#m#qbq",
".K#E#E.K.Kaw#HbMaTaj.a#D#1am#U......#UbY#NaG.qaGaP#paw.2bJbn.Z#x.raJ.6#0ayba#J#ibF#ub0bDba#Sa4#wba.oaW#za4af.fa.baa..mayba#wb0#a#L.R.Uba#z#LaJ#q.z.n#n#q#k#k#qbq",
"ba.C.K.C.K.Cax.W.3.pbmaxaD#g#U#X..aG.J.J.#aPaqbd.x#paBaZaQ.z#E#H.raJ.I.I.oba.GaRbF#x#6bD#7af#Ja.ba#abn#zaybU.za.babD#7.UbabDb0#a.o.i.ob0aRb0.r.z.z#t#i#obKbK#m#d",
"ba.K.C#E.K.Kaw.W.3bM.f.5.MbobCaF..#YbY.Jbu#Y.V.xbd#p#haEby.Z.Z#u.L#k.T#Ra7aR#tavbvba#aa8bk#q#ZbDba.X#S.0bkbs#xbvba.Xba#6#7.o#q#Say.z.o#a#a.z.z.z#t.z#m.ia7.T.Ibq",
"#E#E.C.K#7#EaB.L#ybMbMaAaN#v.P.J...JaF.F.J.HbIbd.V#pab#A.z.Z.Z#H.r.6#k#o#qay.oa4a4.XaW#tbs.obsbr.Xbs.g.Xbraf.X#J.Xafbraf.X#J.XbF#JaX#wbU#Z#t#t#r#r#i#6#m.wao#m#d",
"#E.K.C#Eaw#Eaw.3bhbh.p.8.kaIb3#e#U#XakaiaG.7bI.V.VaV#Kbi#q.z#x.L#u.r#obR#u#x#ta3aW.Z.Z.ZbP.z.Z.n.n.Z.Z.Z.Z.Z.z#t#H#r#u#r.z#r#q#obm.9#x#aa3.z.z#r#r.i#ma7ao#o#3bq",
"#E#7#E.C.C.K#E#ya2a1bN#vbAbEbA.ebu.#.Pbd.eak#X.uaPb3aEa5#R#R.r#ubR#o#o.r#u#H.Z#x.Z.Zbq.n.Z.Z.n.z#tbq.Zbqbq.Z.Z.Z#t#u#r#u.r.i#kaJbR#m.Xbs#u#t#r#u#q#maR#O#b.T#obq",
"#E#E#7.K#Eba#E.f.laibe.ub1#BbY.M.J#X#F.P.VakblaNbZ.FaYar.I.6.6.6#RbR.r#u.r#u.Z#H.Z.Zbq.Z.Z#t.n.z.zbq.n.n#t.Z.z.Z#H#u#u#q#k#O.I#oaJbm.r#r#H#t#u.i#R#m##bVau#p#q#d",
".Caw#E.C.C.C.KaBaAaZb1.a.x#F.J.J..#Ubu#X.O#N.M.Mauak#K.j#NaVbzaQbz.D#obR.r#r#H#t#r#t.Z#t.n#ibk#n.z.z#t.Z#t.z.z#u#rbR#o#R#ObJ#O#kaJ.3bm#u#x.zb0#kaRaQaraV#4#0#r#d",
".C#E.K.C#7.K.K#tbTbAbY.paF.u#2aS.J#g.qb3#NaPbW#KaabObOag.Y#hawawa0ambz#mbR.r#u#u#H#u#r.z#q.TarbL.R.R#i#n.i#q#q#q#ubR#0#0bBbJbV#0.6bKbR#u.r#ma7aQbB.w##ao#p#m.R#d",
"aB#E#Eaw.Caw.Kax.W.aa#bE.e#B.eaS#U.J.#aqaP.Vau.b#A.Z.n.Z.Z.Z#E.K#7#EaBbya6#T#9#1.r.r.r#o.T##aYaHbBab.Q#P.Q#h#h#c.Qa0bzaHaEbtbJbBbBbT#q#r.RaR.wa5.Db.#3#m#m#mbgbq",
".K#E.K#E#Eaw#Eaw.fbM.pbE#B.tbo.Jbu.Jbu#e.VaPaqauataw.Z.Z#7#7#7#E.Z#E#E#E#7.Zbnat#Tahah#2bx#AahaD.Q#h#V.Z.Z#E#E#E.Cbq.z#n#c.Rat#M.n#Ebqbq#d.Cbq.Cbqbq#dbqbn#nbq#d",
"#E.K#E.C.K#Eaw.C.f.W.pbEai#X.M.t.J#e#.blaGbIaq.H#x.Zawaw#7aw#E.n#x#E.Z#E#E#E#7aw#E.n.n#t.nbP#Eaw#7aw#7#Eawbq#Ebq.Cbq#dbq.C#Ebq#dbq#d#d#d#dbq#d#d#d#d#d#d#d#d#d#d",
".C#E.K#Eaw#E.KaB.n.L.3aF.8ai.eaa.JaGaPaab4#N.b.vaw.zaB#7#7.n#7#E#E#7#E#E#E#E#Eaw#E#E#Eaw#E.Z#E#Eaw#7aw#E#E#E#Ebq.C.C#d.Cbqbq.Cbq#d.C#d.C#d#d#d#d#d#d#d#d#d#d#d#d",
".C.C#Eaw.K.K.Kawaw#1.NaA.x.xbd.q.Jb3.V.V.b.qbL.n#x.faB#x#E#7#E#Eawaw#7#E.n#E#E#E#E.n#E#E#Eawaw#E.naw#E#E#Ebq.C.C#Ebq.Cbq.C.C.Zbq#dbq#dbq#dbq#d#d#d#d#d#d#d#d#5#d",
".K#Eaw.CaBawaw.K#EawbT#Ba9aIaIbd.M.e.V.V.baHaB#7.n#x#t#E.n#E#E#7#7#7.n#E#E#E#E#E#E#Ebq.Z#E#E#E#E#E#7bq.n#E.C.Cbq.C.C#d#dbq#dbqbq.C#d#d#dbq#d#dbq#d#d#d#5#d#d#5#d",
"aw#E#E.K.K.Kaw#E.KawaB#1aK.xa9aIaqbd.VbJ.vaB.Z#E.ZaB#xaw#E#Eaw.naw#E#7#E#E#E#E#E#E#Eawaw#Eaw.Z#E#E#E#Eawbq#E#Ebq.C#d.C.Cbq.Cbq#d#d#d#d#d#dbq#d#d#d#d#d#d#d#d#d#d",
"#E#E.C#Eawawaw#7aw#7aBaBaB.R##aP#4a0b.aB#x.n#E#7#E#7#E#E#E.n#7#7aw#7#E#E#E.n#E#Eaw#E#E#E#E#E#Eaw#7bqawbq.Z#E#E.C#E#dbqbq.Cbq#d.C#dbq#d#d#d#dbq#d#d#d#d#d#d#d#d#d",
"#Eaw#E#Eaw#7aw.K.KaB.K#7aBawac.day.ZawaBaB.n#7bqaw#Eaw#7.n#E#E#7#E#7#E#E.Z#E#E#Ebq#E#Ebq.n#E#Ebq#E#EbqaB#7#E#dbq.Cbq.Cbq#dbq#d#d.C#d#d#d#d#d#5#d#5#d#d#d#d#d#5#d",
"aw#E.C#E.KaBaBaw#E.KaBaBaB.r.d.dbnaw#x.n#7awaw#7#E#E#7aw#7#7aw#E#7#E.n#E#E#E#E#E#Eaw#E#E#Ebq#E#E#E#Eaw#E#E.Cbq#E.C#d#d.C.C.C#d.C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"aw#Eaw.KawaB.K.Kaw#7aBaB#7#z.d.m#x#Eaw#7aw#7#Eaw#E#E#E.Zaw#7#E#7#7aw#7#E#E#E#E#E#E#E.Z#E#E#E#E#E#E#E#E#Ebq#Ebq#dbq#d.Cbqbqbq#d#dbq#d#d#d#d#d#5#5#d#d#5bq#d#d#d#5",
"aw.K#EawawaB.Kaw.K#7.fay.G#L.d.m#7#7aw#7#Eaw#7.n#E#E#E#7aw#E#7.n#7.n#E#E#7aw.Zbq.n#Ebq#Ebq.n#E#E#E#E#E#Ebq.C.C.C#d.Cbq.C.C#d.C.C#d#d#d#d#d#d#d#dbP#5#d#d#dbq#5#d",
"aw#Eaw.CaBaBaB.KaBaRacaM.o#L.d.d#LaB#7.naw#Eaw#E#E.n#Eaw#E#E#7#E#7#E#7#E.Z#E#E#E#7bq#E#Ebq#7#E#E#E#E#Ebq.C#E.C.C.Cbq.Cbqbq.Cbqbq.C#d#d#d#d#dbqbq#5bq#dbP#5#d#5#d"
};';
  return $buf;
}

sub england_image {
  my $buf = '/* XPM */
static char *England[] = {
/* width height num_colors chars_per_pixel */
"    77    40      256            2",
/* colors */
".. c #281a14",
".# c #7c827c",
".a c #d4b884",
".b c #881d12",
".c c #884e2c",
".d c #bf7e2f",
".e c #b74c22",
".f c #d49a38",
".g c #e4b848",
".h c #ba6724",
".i c #883325",
".j c #bd9b6f",
".k c #c07f60",
".l c #dfc699",
".m c #cd6821",
".n c #946a38",
".o c #c3cfcc",
".p c #b13418",
".q c #cc4c2c",
".r c #e4c674",
".s c #e39d27",
".t c #704a28",
".u c #d6812a",
".v c #a29c84",
".w c #e6ab37",
".x c #a91a10",
".y c #561d12",
".z c #b75c26",
".A c #e3b86f",
".B c #ac4c1c",
".C c #c1915b",
".D c #d26b48",
".E c #b66851",
".F c #dca577",
".G c #c43d1f",
".H c #b4b7b0",
".I c #ccdbda",
".J c #58331a",
".K c #a35b43",
".L c #dd9d53",
".M c #da922a",
".N c #ae8142",
".O c #e4d898",
".P c #e4c073",
".Q c #a2371e",
".R c #a46d21",
".S c #b1411c",
".T c #b84d36",
".U c #c4b9af",
".V c #a92a15",
".W c #721d16",
".X c #c38f46",
".Y c #caad80",
".Z c #88281f",
".0 c #a58681",
".1 c #afaea5",
".2 c #a06858",
".3 c #cdd1cb",
".4 c #a14c3c",
".5 c #d07624",
".6 c #e2ac5c",
".7 c #d68f62",
".8 c #b67558",
".9 c #b9541f",
"#. c #944418",
"## c #dc8157",
"#a c #ecc879",
"#b c #e5a42d",
"#c c #dce2dc",
"#d c #a25342",
"#e c #cc5e24",
"#f c #b95e43",
"#g c #be813e",
"#h c #b97329",
"#i c #d79343",
"#j c #ecc177",
"#k c #742818",
"#l c #c2966d",
"#m c #d2734a",
"#n c #b0c7cf",
"#o c #f4da9c",
"#p c #ecbf4c",
"#q c #b09a8c",
"#r c #be8862",
"#s c #bc4521",
"#t c #bc3819",
"#u c #d98644",
"#v c #aa2010",
"#w c #981c10",
"#x c #c44d21",
"#y c #dea457",
"#z c #b72915",
"#A c #3e1a15",
"#B c #cd9c6e",
"#C c #ecb971",
"#D c #d4dddc",
"#E c #a7743c",
"#F c #bcb0a4",
"#G c #a4926c",
"#H c #d17539",
"#I c #c47353",
"#J c #edcf88",
"#K c #d15f3b",
"#L c #8f602e",
"#M c #e1b06e",
"#N c #af8e5f",
"#O c #c9c6b6",
"#P c #7c1f1a",
"#Q c #ccd5d5",
"#R c #c28841",
"#S c #c46d25",
"#T c #943424",
"#U c #ebd19a",
"#V c #c4d2d5",
"#W c #b23a19",
"#X c #ac6047",
"#Y c #b1442d",
"#Z c #992818",
"#0 c #a07650",
"#1 c #ecaf5e",
"#2 c #bcc5c5",
"#3 c #ca9c54",
"#4 c #ecb747",
"#5 c #df9d40",
"#6 c #6c665c",
"#7 c #d4872a",
"#8 c #e9b23c",
"#9 c #cc9461",
"a. c #e1c087",
"a# c #6c3a34",
"aa c #7c5e3c",
"ab c #8c7761",
"ac c #582e20",
"ad c #948d81",
"ae c #a2411e",
"af c #644624",
"ag c #797971",
"ah c #d0c49c",
"ai c #6c3e14",
"aj c #af936c",
"ak c #949e9c",
"al c #d4a75c",
"am c #402620",
"an c #8c5f57",
"ao c #321f14",
"ap c #c7ba9c",
"aq c #846e54",
"ar c #a8865c",
"as c #9f6b37",
"at c #8b4034",
"au c #947f6c",
"av c #f5e49e",
"aw c #7c423c",
"ax c #944f37",
"ay c #7c4a2c",
"az c #d4ad78",
"aA c #ecdebc",
"aB c #d4cac4",
"aC c #ac7455",
"aD c #c88828",
"aE c #a1561c",
"aF c #b8553a",
"aG c #aea599",
"aH c #a4a6a4",
"aI c #9f938a",
"aJ c #9d4333",
"aK c #ecd79b",
"aL c #c45d2c",
"aM c #c46a48",
"aN c #643224",
"aO c #b48a6c",
"aP c #ac6a4d",
"aQ c #c4742c",
"aR c #7c271a",
"aS c #dc7649",
"aT c #d49b4d",
"aU c #7c3420",
"aV c #642818",
"aW c #c2a473",
"aX c #d88860",
"aY c #885048",
"aZ c #d16b3b",
"a0 c #641e12",
"a1 c #dcaa8c",
"a2 c #e49524",
"a3 c #cc9244",
"a4 c #c45e40",
"a5 c #cc9272",
"a6 c #dc6244",
"a7 c #c5cac9",
"a8 c #9c736a",
"a9 c #b4815c",
"b. c #ac6a40",
"b# c #944434",
"ba c #ce542f",
"bb c #c74524",
"bc c #cea374",
"bd c #cc8964",
"be c #ccb294",
"bf c #ecb26c",
"bg c #ecc999",
"bh c #dc6a45",
"bi c #4c1a14",
"bj c #94665c",
"bk c #341614",
"bl c #c46a36",
"bm c #cc8127",
"bn c #e3b763",
"bo c #cc8158",
"bp c #e3c98a",
"bq c #dcb888",
"br c #dcd6b4",
"bs c #ac4d3a",
"bt c #c45618",
"bu c #e5a33d",
"bv c #ac533d",
"bw c #ebc05f",
"bx c #cc8940",
"by c #f4d294",
"bz c #c45639",
"bA c #bc6e34",
"bB c #843a1c",
"bC c #705234",
"bD c #bc6220",
"bE c #b96e4c",
"bF c #5c3a28",
"bG c #9f624a",
"bH c #ccb284",
"bI c #8c2e28",
"bJ c #9c6e64",
"bK c #e2b264",
"bL c #d89654",
"bM c #b47a34",
"bN c #702e18",
"bO c #d07a52",
"bP c #972216",
"bQ c #b41a14",
"bR c #b4210f",
"bS c #a49b98",
"bT c #ecc987",
"bU c #ecc187",
"bV c #ecb962",
"bW c #ecdab0",
"bX c #d4e2e1",
"bY c #c47a54",
"bZ c #bccacc",
"b0 c #7c521c",
"b1 c #c46224",
"b2 c #d4a25e",
"b3 c #882216",
"b4 c #cc6e1c",
"b5 c #c4d6cc",
"b6 c #54221c",
"b7 c #c29658",
"b8 c #deaa70",
"b9 c #b9beb8",
/* pixels */
"bZ#Q#Q#Va7#V.3#V.3a7.oa7a7#2.o.oa7#2a7#2a7a7#2a7#V.o#V.o.3.o.o#V#V.o.obZbZ#2bZ#V#V.o.obZbZ.o#V.obZ#2a7b5#Va7#V.o.obZ.o#V.o.o.obZ#V#Q#V#V#V.o.o#Va7#2.o#V.o",
"#Q#V.o.3.o#V.o#Q.3#Qa7#Va7a7.3.oa7.o.oa7.o.3a7bZa7.oa7.3.o#V.o.3.o.o.o.obZbZbZ#Va7.obZbZbZbZ.o.o.oa7#Va7#V#V.o.o.o#V.o#QbZ.3#V#V.o.o#V.3#V.o.o#V.o.o.o.o#V",
".obZa7bZ#V.oa7#Q.3.o.o.oa7#V#Va7.3#Q.o#Q.3.o.3a7a7.o#Qa7.3.3#Qa7#V.o#VbZ#V#V#V#V#n.obZbZbZ#VbZ#V.obZ.o#V.o#Q#V#Qa7#V.obZ#Q#V#V.o.o#V.3b5#V.3.o.o.3.o.3#V#V",
".o#VbZ#Va7.3.o#V.o#Q.3a7.3a7#Q.oa7.3.3a7.3.3.o.o.o.3.o#V.3.3bZa7#V.o.o#VbZ#V#VbZ#V#VbZbZ#V#V#V#V#V#Q#V.o.o#Q.o.o.o#Q#V#Q#Q#Q.o.obZ#Vb5#Q#Q#V.o.3.o.3b5.3#V",
"#Va7bZ.obZb9.H.1aH.H.1.1aHaGaGaIadaIbSaIaIaIbSaG.1.Hb9#2b9b9#V#V.3#V#VbZbZ#V.obZbZ#VbZ#VbZ#V#Q.o.o.oa7#Va7#V.3.3#V#Q#Q.3#Q#V.3bZ.o.3#Q#Qb5.o.o.o.o.o#Vb5.3",
".3.o.o.o#Gb#bvaFaFaFaFaFbz.Tbs.TaFbzbzaF#KaF.TaF#Y#Y#YaJ.Qa#b9#Va7#Q.o#VbZ#V#VbZ#VbZ#V#VbZ#V.obZ.o#V#Va7#V.3#V#V.o#V#V#Q.o#Vb5bZ.o#Q#V#Q#V#V.3.3.o.o#Qb5#V",
".o.o.3a7.0aFbO###m#maS.D#maS#mbhbzba.q.e.qbz#x.qbbbbbb#z.V.ib9bZ#V#Q.o#V#V.ob5bZ#VbZ#V#VbZ#VbZbZ.3#VbZbZ.o.o#V.o.o#V#VbZ#V.oa7#VbZb5#V#V.o.o#V.o.o#Vb5#V#V",
"#Q.o.oa7a8a4#mbz.D.Dbh#K#Kbh#K#K#Kb1b1aZbt#x#s.G#t#s#s#W#vbIb9#Va7#VbZ.o#Q#V#Q#V#VbZ#Va7#V.o#Va7#V#V.o.o.o#V.o#V#V.o.ob5.3.o#V#VbZ#V#Q#V#Vb5.3b5.3b5#Q#Q#V",
"#V#Q#Qa7bjaMaX.s.D#K#K.D#KbabababmblaS#HaZ#m#m#u.5#u.ubA#v.ibZa7#V.3#V#V.o.o#V.o#V#V#V#V.o.3#V.o#Va7#V.o#V.oa7.o#Q#Q.o#Q.o#V.o.o.o#V.3b5.3#V.3#V#Q#V#Q.3.o",
".obZ.o.obj.DaX.6.5b1bobLbLbb.qa6#m.u.u.5b4b1aZ#s.V#v#v.x#v#T#2.3.o#Q#V.3.o#Q#Q#Q#V#Q.o#V#V#V.3.o.3#Q.oa7.3#Q.3.o#V.3#V#V.3.U.v#O.o.3.3#Qb5#Q.3.3#Vb5.I.o.3",
"#D#Q.o.3bj.Dbh#K#5a2.6#4#4#mbOaSaZaLaL#s.ebu.Q#v.x.x#v.Q#v.ia7a7bZ#Q#Q#2#V#Q.o#Q.o.o.o#V#Q#Q#Q#2.H.1adab#GaOaGaWaGaG.1aGau.N#R.d#NaW.l.laWabaqagbZ.3#V.3.o",
"#V.o.obZa8.DaSbh#HbK#pbV.g#8bw#pbwbw.g#4#8.w#1bx#S#H#y#m#w.iakag.##6bCaaaaaIaG.1aI.v#qadagabar#Nas.Jas#haT.A.Pbp#U#Ua..P#5bxa3#yal#j.PbpbTbp.P.t.Hb5b5b5b5",
"#Q#Q.o.oa8#mbhbh.D##b2.w#4#b#4#p#8.M#SbDbm.s#b.s.s#5.f.L.Q#P..ao.Jaf.N#gbM#R#R.Cbcaz#Mal.Cb8#M#yb8#EaT.d#ybn#j.rbp#UbT.A#C.6.A.P.PbTbp#J#J#Jb7b7.v#V#V#Q#Q",
"bZ.o#V.3a8a4#Ka6bhaZ.6#p#b#7.ubmb1.Q.5.u.s.MaQ#5#H#ZbDbu.V#k..ac#L#gaTb2a3#3#Ma.#abpbpbTbTa..Pa..A.A#y.Xb2bw.P#J#U#UbT#jbK#M.PbT.P#UaKaKaK.r.rbn#q.o#Vb5b5",
".I#Q#Q.o.0#K#K.D#u#4#8.w.5bb.GbR#W.pae.s.s.u.S.p#w.S#i.6#Z#Zaob0.N#Rb7al.Xb7.AbTbTbp#J#Uby#U#JbT.P.Pb8aT#ybn.r#abpaA#obU.6.6.Pbp#U#oaAbW#U#a.rbn.v.o#Qb5#Q",
"#D.o.oa7.0.T##.A.w.MaD.uba#z#z#vbv#y.Mbx#SbE#v#v.V#Ib2aF.xb3ac.caJ#Xbv#.#dbG.Pa.bTbpbg#U#o#U#U#J.A#daJb..6bw#a#J#UaA#UbTbKbK.P#Jbc#d.4.8#J.P.r.faG#Vb5#V#V",
"#Q#V#2#V.0bs.G#HaZ#K.G#t#t#z#zbQ#Wbt.S#W.p.p.p.p.p.p.V#v.xb3bNbY.l.Kbv#rbU#Xbw.P#U#U#UbybW#U#UbgazaC#o.Kbn.Pbp#JaKaAbybU.A.A.r#Ua5.8avaP.r.Pbn.Xap#Q#Q#V.I",
"#Q#V.o#Q#qae.qbb.Gbb#t.5#i.5bR#Wb1.9.S#s.B.e.e.9b1bm.5#v.x#Z.8#oaP#M.PbEbpb.azbc.Ybe#lbr#obe#raW.a#dav.K.6#r.Naz#Ube.Ybc#r#Mbpa.#raYavb..rbnbKb2ah#V.I#V#V",
"#D.I#Q.o.U.Q.DbL#s#z#z#i#4#y#v#v#s.9btb4.m.m.m#e#z#v.xbR.x#Zby#oax#B#r.K#l#E#T#I.EaFaX#daC#f.kbO#fatav#d.4.8bd.E.i.8#Ibv.7#dbc.4a5.kavbEbwbn.6#Rahb5b5#V#V",
"#D#Q#V.3aB.i.p#5a2.m.pbx#8bVb4bt#s.S.S.9.9.u.M#s#v#v#v.x.xbsav#o#IbY#9.FbU.8#IaW#obGbW.k#X#o.W#oaOatav#d#B.k.Kav.i#r#o#d.l#B#P#jaC.2avb..Pal#5.N#O#V#V.I#V",
"#D#D#Q#Q.3bI#zbAa2.sa2#8#b#4.s.w#p#8.w#b.s#b.s#b.m#5bl#v.x#davaKbG.K.K.Kbc.8bc#l#U.Wbp#Ba9by#P#U#rb#av#dbjb#.8avb#a9#o.W.Yazb##oaxb#avaPbwalaT#g.3bZ#V#V#V",
"#V#Q.I#Q#QbIbR.x.T.z.7.z#i.w.s.s.s.5.Bb4#7#Wbt.M.5#Sbu#Z.xaeav#o#dbgbga1a9.8#M#l#U#P#Ua5ataKbv#U#daJav#daJ.FaPavb#a9#ob3azazaxav.4aJavb.bn#ia3.R.o#VbZ.I#V",
".I.I#V.I#Q.i#v#Y#K.p.p.5.s#5.B.V#Z#Wb4a2b4#vbR.V#v.V.u#u#v.bbHavaPbe#U.8a1.8a5#l#U.WbTa5bI.Fat.Z.K.Kav#dbq#B#davaJa9#o.Wazaz.iavbGb#av#XalaT#R#E#2b5#V.I.I",
".I.I#V#Q#QaY#v#W.6#ba2bm#S.V#v.e.5.Sa2a2.5#t#vbQ#v.p.hae#va0aN.a#Ubvbs.kaK.k.Eaz#U.Q#obqaC#obgbU#I.K.O.8.YaKaO#UaCa5aK.4bqahb3.Ca..Cbp.8#g#y#g.n.o#V#V#V#V",
"#Q#D.I.I#Qan#v#v.e#S.S#v#v#v.x.Q.u.5bD#W#W#xbt#x.V.b.W.W.b.yay#f.KaCaP#d#r.8bdbsbsaJ.4ae.4a.#laW#UbIbsaFbvbs#f.4aFbv.4bvbsaFbY.8bsbsbvbY.A.6a3#L#2b5.I#V.I",
"#D.I.I#Q#Qbj#vbQ#vbR.x.V.LbL.e#vbR.p.5bD#.aRbNai.R#hbD#P.bbi#LbnbfbL.F#CaC.8#UbU#C#Mbf.7#r#rb3#T#l#r#U#J#a#a#a#a.A#Cbn#j#a#a.r#a.P#JbKbK.P.6aT#E.o#V.I#V.I",
".I.I.I#D#Q.0bP.xbd.SbQ.V#4#4#s#vbR#zbD.h#h#SaEaE#.#ka0.Wb3ac.nbK.6#jbU#Cbo.kbgbU#C#C.6bfbv#X.8#X.EbgbT#J#J#J#a#C.6.6bK.P#a#a#j.Abn#abnalbwbn#3#0.I#Q.IbX#V",
".I#D.I#D#D.Ub3#vbY#i.p.9#4#p#y.L#ubobA.z.cas.d#7aEaU.W.Wb3am.N#ybf#CbU#CbfbUbgbU#M#M#1.6.A#y.F#C#a#J#J#J#Jby.P.A.6#y.L#3#j#a#abK.6bK.6.6.6bna3#N.I.I.I.I.I",
"#cbX#D.I#Q#QatbR#Wbx#b#b#8#4.s#b.w.w#b#b#b#b#b.g#9a3.i#P.Wao.NbxaT#y#y.6#C#CbU#Cbfb8.L.6bV#jbn#a#a#a#J#a#a#a#j#C#5aT#har#abU#j#CaT#5b2aTaT#y#R#N.I.I#Q.I.I",
"#D.I#D#D#Q#Q.0#ZbQ#t.8bd#f#i.s.s.M.s.M#haD.d#La2.w#Mb3#wb6ao#L#E#RbxbL#y#M#Cb8#Mbf#y#i#5#ybVbVbV#j#a#a#a#abw#j#M#5bx.taja.a.#j#M#y#R.dbx.X#5#Raj.I#D.I.I#D",
".I.I#Q.I#D#Qa7.ZbR#v#v#v#fbu.sb4b3b3bB.Ba2bB#A.JaE.w#fb3amamaNb0as#0ar#l.ja9#9.6.L#ubL#i.Lbf.6#M#C#j#a#a#j.Pb8b2aT.C.U#D.3brahbH#Ma3.Xa3aDa3#i#qbXbX#D.I#D",
".I.I.I.I#D#Q#Qan#Z#f.7#5.w.s.5b3.bb3.h#b#b#h#AbkaV.fbobG#F#O#O.3#D#Q#Q.3#Q.3#O#l.Xbxa3#u#i#y.A.AbUa.az.j.j.j.jar.YaB#D.I#D#Q#Q.3#Oap.YaW.Aalb7aG#D#D.IbX.I",
".I.I.IbXbX.I#QaG#P.VaQbx.Sae.b#w.h.Bb4.w.dbibkbFal.6bB#2#D#Q#D#D#D#D#D#Q.I.3#D#Qap#B.X#Ra9.jbr#D#c#D#D#D#D#D#Q.I.I.I#D#Q.I#D.I.3b5.I#Q#Q#D#Q#O.I.I.I.I#DbX",
"bX.I#D#DbX#Q#D#QaY.Z#vbP.b#P.bb3b..s.Rb0#Abk#A#A.t#T.0#c#D#D#DbX#D.I#D#Db5.I.I#D#D#D.3#Q.I#D.I#Q#D#D#Q.I#Qb5b5#Q.Ib5#Q.I.I#Q.Ib5.I#Q.I.I.I.I.I.I.I#Q.I.I.I",
".I.I.I.I.I#Q.I.Ia7atbP#w.b.b#P#P.WaVbi..bkbkbk#A#Pan#D#Q#D.I#D#DbX#Q#Q#D#D.I#D#D#D#DbX#D#D.I#DbX.I.I.I.I.I.I.I.I#D.I.I.I.I#D#D.I#Qb5.I.Ib5#Db5#D.I.I.I.I.I",
".I.I.I.I.I.I.I#Q#D#Oat#Z.b.b#P.W.W.y#Abkbkbkbi#Pawa7.I#D#D#D#D.I#D#Db5#Db5#D.I.IbXbX#D#DbX#DbX.I#D.I#D#D.I.I#D.I#D.I#D#D.I#D#D.I#D.I.I.I#D.I#D#D#D#D.Ib5b5",
".I.I.I.I#V#Q.I.I#D#V.3an#Pb3#P.W.W.Wbi.y.ya0#Pan.3#D.I#DbX.I.I#D.I.I#D.I.I.I#D#D.I#D.I#D#D.IbXbXbX.I.I.I.I#D.I.IbX#D.I.I.I#D.I#Q#Db5#D#D.I#D#D#D#D.I.I.Ib5",
".I#V.I.I.I#V.I.I.I#D#Q#Q.HbJaUb3b3b3b3.W#PaUaI#D.I#D#D#DbX.I.I.I#D#D.I#Q.I#D#D#D.I#Q#D#DbX.IbXbXbX.I#DbX.IbX#D#D.I.I.I.I.Ib5#D.I.3.I.I#D.I.I#D.I.I#D#Q#Db5",
"#V#V.I#V#V.I#V.I.I.I.I#Q#Q#Q#OaGaIauabaIaG.3#Q#D#DbX#D#DbX#D.I.I.I.I#D.I.IbX.IbX#D#Db5bXbXbXbXbX.I.IbX.IbXbX#DbX#D.I.I#Q.I.I.I.I.I#D.I.I.I.I.3.I#D#D.I.I.I",
"#n#n#n#n#n#V#V#V.I#V#V.I.I#Q.I#Q#V.I#Q#Q.I#D.I.I#D.I.I.I.IbX.I#D#DbX.I.I.I.I#D.I#D#D.I.I.IbXbXbX.I#D.IbXbX#D#DbXbX.I.I#Q#D.I.I#Db5#Db5.I.I#D.I.IbX.I.I.I.I"
};';
  return $buf;
}

sub spain_image {
  my $buf = '/* XPM */
static char *Spain[] = {
/* width height num_colors chars_per_pixel */
"    72    40      251            2",
/* colors */
".. c #2a0b15",
".# c #519cd4",
".a c #af863c",
".b c #f4c524",
".c c #8e141c",
".d c #b18a81",
".e c #90561a",
".f c #b9c2b7",
".g c #d8aa30",
".h c #cce2ea",
".i c #c71e17",
".j c #d9c391",
".k c #bc5028",
".l c #444644",
".m c #db8917",
".n c #60111c",
".o c #bcaa84",
".p c #c86c14",
".q c #eda816",
".r c #903614",
".s c #d6d6c4",
".t c #d7874c",
".u c #333938",
".v c #e2ab7e",
".w c #e1d3b1",
".x c #c83819",
".y c #e5a848",
".z c #b4c4c4",
".A c #c66a58",
".B c #79b2de",
".C c #ebc564",
".D c #d6971d",
".E c #4c0d1b",
".F c #b41819",
".G c #b3d2e4",
".H c #f2d35c",
".I c #af874f",
".J c #daba7b",
".K c #f3e3b9",
".L c #612d19",
".M c #a16e24",
".N c #d47c5e",
".O c #c72b1b",
".P c #f0d497",
".Q c #e59915",
".R c #e05228",
".S c #b12924",
".T c #e7b856",
".U c #c8d6d2",
".V c #edd5a9",
".W c #d78878",
".X c #e9c47b",
".Y c #9bc4e1",
".Z c #dcba6c",
".0 c #b93227",
".1 c #491f20",
".2 c #8f8a84",
".3 c #e8c497",
".4 c #efb91d",
".5 c #e3ba9c",
".6 c #caa865",
".7 c #c0622c",
".8 c #77161d",
".9 c #e03a19",
"#. c #bc9654",
"## c #d9987f",
"#a c #3c1c21",
"#b c #ebcc7c",
"#c c #d69836",
"#d c #90766c",
"#e c #c0801d",
"#f c #cb6d66",
"#g c #47131d",
"#h c #b0201d",
"#i c #fcf8b8",
"#j c #c5d6dd",
"#k c #d8a859",
"#l c #ca891a",
"#m c #d4863c",
"#n c #ccb884",
"#o c #e6bb7e",
"#p c #91a3a9",
"#q c #390d1b",
"#r c #d9a14a",
"#s c #bc4324",
"#t c #ebcc98",
"#u c #cc9214",
"#v c #9e2322",
"#w c #d4e2e3",
"#x c #d62516",
"#y c #e7a734",
"#z c #bcc4c8",
"#A c #de3015",
"#B c #5c6a6c",
"#C c #e1a98f",
"#D c #e7b263",
"#E c #a1afb1",
"#F c #e8ba6a",
"#G c #f1dbad",
"#H c #f0debc",
"#I c #eed37b",
"#J c #f4e9cf",
"#K c #f3db98",
"#L c #c4604c",
"#M c #c19967",
"#N c #cb7569",
"#O c #d17f71",
"#P c #de451d",
"#Q c #cadde3",
"#R c #dcb063",
"#S c #ac4e34",
"#T c #d6901b",
"#U c #cab07f",
"#V c #d5dddc",
"#W c #462622",
"#X c #d8907a",
"#Y c #7e211e",
"#Z c #d67e16",
"#0 c #54131d",
"#1 c #38131f",
"#2 c #9c141c",
"#3 c #c82318",
"#4 c #5c2224",
"#5 c #f7ebb9",
"#6 c #6f3d24",
"#7 c #e4a03c",
"#8 c #b42e44",
"#9 c #a2cbe2",
"a. c #f4cd7f",
"a# c #6c4e34",
"aa c #a87e38",
"ab c #7c5a34",
"ac c #946664",
"ad c #b4a27c",
"ae c #914619",
"af c #746e64",
"ag c #947b64",
"ah c #b8babf",
"ai c #b2711c",
"aj c #9e9e9a",
"ak c #a7631c",
"al c #96bee1",
"am c #bf5758",
"an c #9c8c7c",
"ao c #782e18",
"ap c #f0c644",
"aq c #94652f",
"ar c #c8462c",
"as c #afa8ac",
"at c #b4343c",
"au c #ccc294",
"av c #80461c",
"aw c #d45a14",
"ax c #64a7da",
"ay c #88bbdf",
"az c #ac4634",
"aA c #a03838",
"aB c #84aac4",
"aC c #94724c",
"aD c #443430",
"aE c #984a3c",
"aF c #9c6a68",
"aG c #7c5c54",
"aH c #c15a39",
"aI c #e8bb34",
"aJ c #c47c38",
"aK c #d89a64",
"aL c #daccae",
"aM c #d48864",
"aN c #c6c9b9",
"aO c #8cb6d4",
"aP c #7c4e4c",
"aQ c #efcb69",
"aR c #b68f50",
"aS c #6c361c",
"aT c #b63b1a",
"aU c #dda183",
"aV c #847a74",
"aW c #b73b46",
"aX c #f4d244",
"aY c #dc5d34",
"aZ c #d43618",
"a0 c #cc624c",
"a1 c #dcb240",
"a2 c #63171c",
"a3 c #c37418",
"a4 c #f0b018",
"a5 c #b0cce1",
"a6 c #909690",
"a7 c #ca9f4c",
"a8 c #6c767c",
"a9 c #e2b091",
"b. c #f6dc81",
"b# c #c7a164",
"ba c #a0938c",
"bb c #aca2ac",
"bc c #d88038",
"bd c #942e24",
"be c #bcd4e0",
"bf c #bc2c1c",
"bg c #ecbe94",
"bh c #7c3e14",
"bi c #b47e30",
"bj c #bc4842",
"bk c #f4db64",
"bl c #a1a8a6",
"bm c #b2b1b2",
"bn c #cc6234",
"bo c #ca9335",
"bp c #ecaa84",
"bq c #cc3a34",
"br c #541c1c",
"bs c #84161c",
"bt c #cc7d19",
"bu c #c48e34",
"bv c #e49c54",
"bw c #d4e5ec",
"bx c #c36360",
"by c #542a24",
"bz c #6c1e14",
"bA c #9c827c",
"bB c #f4be2c",
"bC c #e4a25c",
"bD c #e7af49",
"bE c #cc7356",
"bF c #d99f1d",
"bG c #e8a016",
"bH c #d9a03b",
"bI c #d58f33",
"bJ c #e7af2f",
"bK c #c1cccd",
"bL c #a01c1e",
"bM c #d98f69",
"bN c #cc5034",
"bO c #fce6ac",
"bP c #bc8a7c",
"bQ c #ec3e14",
"bR c #b46614",
"bS c #2c141c",
"bT c #8e1b1e",
"bU c #5c524c",
"bV c #a0766c",
"bW c #cc6662",
"bX c #dca64c",
"bY c #d42c15",
"bZ c #a4c5e3",
"b0 c #cc9946",
"b1 c #d46e64",
"b2 c #bc2019",
"b3 c #d47568",
"b4 c #e49114",
/* pixels */
".u.u#pbe#Q#w#Q#Qbe#Q#j.h#Qa5#Q#Q#j#9bw#Q.h.h.h.h.h#w.hbw#Q#w.h.h#wbw.h.hbwbw#wbwbw#w#Qbw.h#wbwbwbwbwbwbwbwbwbwbwbw#Q.h#w.h#Q.h.h.hbwbw.h.h.h.h.h",
".u.u#p#Q#Q#Q#Q#Qal.G.h.hbe.Y.h#Q#9.Y#Q.h.h.h#wbw.h#w.hbwbwbw#w.h.h.h#Qbwbwbw.h.hbw.h.h.hbw.hbwbwbwbwbwbwbwbwbwbwbwbwbw.h#Q.h.h.hbwbwbw#Q.h.h.h.h",
".u.u#pbK#Q#Q#Q.Y.Bay.G#9.Yay.Ya5al.Y#9.G#Q.h.hbwbw.h#wbw.h.h#w.h#w#Q.h.hbw.h.h#wbwbw#Q#w.h.hbwbwbwbwbwbwbwbwbwbwbwbw.h.h.U#Q.h#w.h.h.h.h.h.h.h.h",
".u.u#pbe.Ga5alala5#9bZalbZala5a5.G.G#9.Gbe#Q#Q#w#Q.h#Q.h#w.h#wbwbwbw.h.h.h#w.hbw.h.hbw.h.hbw.hbwbwbwbwbwbwbwbwbwbw#w.h.h#Q#Q#Q.h.h.h.h.h.h.h.h.h",
".u.u#p#j#j#Q#j#j.ha5be.h#j.G.Gbebe#Q#Q#Q.h#Q#j#V#Q#Q#Q#w#w#Q#w.h.h#w.h#Q#w.hbw.h.h.hbwbw.h.hbw.hbw.hbw.hbwbwbw.hbwbwbw#w.h.h.h.h.h.h.h.h.h.h.h.h",
".u.u#p#j#Q#Q#j#j#j#Q#Q.h#Q#j#Q#Qbe#Q#Q#Q#V#Q#Q#j.U#Q#w#Q#Q.h#Q.h#Q#Q#w.h.hbw.h.h.hbwbw.h.h.hbwbw.h.h.hbwbwbw.hbwbwbwbwbwbw.h.h.h.h.h.h.h.hbw.h.h",
".u.ubl.U#jbKbKbe#zahbmbbbmbmbmbbbbasbmahbmahbmbmasbbah#zbK#Q#V#Q#w.h.h#w.hbw.h#wbw#w.h.hbwbwbwbw.h.hbwbw.h.hbwbwbwbw.hbwbwbw.h.h.h.hbw.h.hbw.h.h",
".u.ublbaazbjaraW#s.Sbq.S#hbf#h#v#h.F#8bL#v#vbT#v#v.SataAaA.2bwbw#Q#w#w.hbwbwbwbw.h.hbwbwbwbwbwbw.hbwbwbw.hbwbwbwbwbwbwbwbw.h.hbw.h.h.hbw.hbw.hbw",
".u.u#EbA#P.9.9aZ.O.ib2.i#x#x#3b2b2b2.i.i.i.Fb2.Fb2#h#hbL.0.2#V#w.h.h#w.hbw#wbw#wbw.hbw.hbwbwbwbw.hbwbwbw.hbwbwbwbwbwbwbwbwbw.h.h.h.h.h.h.h.h.h.h",
".u.l#E.d.9.9aZ.9#3.i.F.F.i#xbNaraw.S.x.i.F.i.F.F.F.FbL#h#hba#Q#w#Q#Q#w#Q#w.h#Q.h.hbwbw.h.h.h#Q.hbwbwbwbwbwbwbwbwbwbwbwbw.hbwbwbw.h#Q.h.h.hbwbw.h",
".u#B.z.d#P.9.9#Abqb2.i#3.i.i#O#DapbDb4.i.F.F.F.F.FbLbLbL#Yba#Q#Q#w.h#Q#w#w.h#w.h.h.h#Q#Q#w.U#Q.hbwbw.hbwbwbwbwbwbwbwbwbwbwbw.h.h.h.h.h.h.h.hbwbw",
"a8#pbKbA#P#A.9#A#3#3.i.i#x.iar#Mb##kawb2.F.F.F.F.F#2.cbs.8aj#V#Q#Q#w.h#w#w.h#Q#Q.h#w#Q#wbw#Q.h.hbw.hbwbwbwbwbwbwbwbwbwbwbw#Q#jaN#z.U.hbwbwbw.hbw",
"#zbKbKbV#P.9.9#A#x#3.O.O.ib2b2bva7#y.xarbIaT.m.F#2.c.8.8a2a6#V.UbK#j#V#V#V#Q#w#w#V#VaNaLaL#n#U#n.6#n.obaagb#aRb#.6.6.6.J.6.6#n.Z.Jad#Q.hbw.h.h.h",
"bebe#jbV#PbQ#A#A#x#xbMbCbc.pb2#ybFbG.xbN.X#F#T#2#2.8.8.8a2#a#6ak.M.a#.#Mb#.6#U.j.J#o#F.XaQ#IaQ#F#Ra1#c.Mbo#R#R.Z.X.C#b.P.P#b.X#b.X#o#V.hbwbw.h.h",
"be#Q.UaF#P.9#A#AbY#xaraKbH.0.i.yap.q.O.ibt#u.r.cbs.nbsa2a2#a.eai#c.y#F#t.P#b#I#I.P#b#I#baQ#I#t#t#D#R.ybo#R.X#b.P#G#K#H#G.V#G.P#t#b.j.Ubw.h#w.h.h",
"#Q.U#jaF.R#A#A#A#x#x#3#rbtaT.ibDaXa4.O#3bc#l.r.8.8.8.8.n.8.1akbi#c#r.3.P#t#I.P#I#K#I.P.V.P.P.w.P#b.T.T#R#o.P.P.K#G#H#H#G#G.V#t#I.w.Xbw#w.h#w#Q.h",
"#j#j#jac.R.9.9#A#xbY.O.ybJ.xb2#yaXa4.Ob2#rbBao.n.8.8.n.E.8byaka3#c#o#t.5a9#t.V.P#t#t#G.V.V.V.V#t.X#F.Z.Z#t.3#X.w#J#J#G#H#G#t#G.PaLaL#Q.h.h.hbw#w",
"#j#j.U#d.R#A#AbYbYb2aT#RbHboaTaJbu.Q#T.ka3#TbR.E.E.8.E.n.8.1ak#e#Ra9bx#O#O#N#faUbWbx.V.V.V#G.Pa.#b.C.X.C.w#f.V#N#J#J.K#H.V#b.V#I.ZaL.h#Qbw#wbwbw",
"#j#Q#jbA.R#A#AbY#3aZ#G.6.g#IbFa1.4.D.4.D#TbGbta2.E.n.E.E.8bybRai#k#f.3bx#Nb3#G#C.3bW.K#J.K#G#G.Pa..5.j.3.wbW#Gb3#J#H.K.3.5#b.V.C.Z.w.h.h.h.h#Q.h",
"bebe#jbAaY.9bY#x.ibf.5#n.T.gbF.gbF#ubF.m#l#u#e.E.n.n.E#0#YaSaibu#maU#G#L.AamaU###Oat#O#fbx#ObW.5bW#O#XbW.AbWbWaW.N#Oam###N###t#b.J.s#wbwbw.h.h.h",
"a5be.Ua6aY.9bY#A.ib2bf#o.6apaIaI.q.q.qbGa3#Zbz.E.n.n.n.n.8avai#T#m#X#i#ibO#t#t.A.5#N#t#i#X.V#Gat#K#N.W#ibj.W#iam#X#iaUa9#i.A#t#b.X#V.h#Q#Q.h.h.h",
".GbebKblaY.9#A#x.i.i.x#b#I#b.Kbk.q.4a4.q.Q.pbz.E.n.E.E.E.8.e#ebo#D#O#t#i#i#i#i#t#O#Ca9#5#8.N#i#f#Cbx.W#ibxb1#ibxb3#iamb3#i#f.V#b#o#Vbw.h#Q.h.h.h",
".Gbe#jbmbn.9#x#AbY.i#3#D#b#b.CaQ.g.q.q.Qb4.p.L.E.E#q#q.E.8ak#lbH#o#Xbj#LbE.W#K#i#f#C#C#ibj#f#i#ObWbg###ibx#f#ibx#N#iam#f#i#f#t#b.j#Vbw.hbw.h.h.h",
"#9.G#j#z.k#P#AbY#xbY.O#o#b#K#t.H.4.q.qbG.Q#Z.L...E#q.E#g#Yak#T.TaUa9#f#F.X.3bx#5#fa9bp#iaW#O#ibx#5aU#f#i#fbx#ibxb1#iambW#i.A.X.3.C#wbw.h#Qbw#Q#Q",
"#9a5#jbK#S.9bY#A#3#3bf#D.K#b#Kb..b.4bGbG.Q.m.L...E.E.n.nbzai.D.C#O.P#tam##.W.W##a9#CaU#ia9#GaUaW.K#5#C#5a9#X#5aU###H.W#X.V###X.X.X#V#wbw#w.hbw#Q",
".YbZbe#zaE#P#3bY#3#3aH#Fa1aI.4.q.4.4.q.q.Q#u.e#q...E...EaS#e#c.X#faU#LaU.W###O.W.PbpaU#iaWa0aM#D#NbE.W#N#O.N#O#O#O#N#N.7aHbE#F.C.X.s#w#w.h#w#Q.h",
".Baya5.UaE.9#xbYb2aH.VaQ.4.b.bbF#l#l.q.qbGbG.Qbh.......EaS#lbHbM#CbWbX.taM#X.5.Pa..W.v#i#fbvbD.y#b#b.P.P.V.P#t#G.P.3#k#cbo#r.T.Z.X.s.hbw#w.h#Q#w",
".Baybe#QaG#P#3#3bj.J#G#I#bb.b.a7a3ai#la4bG.qbG.p.L#q..#qav#T.TbE#O#m#R#o.P.V.Xa..XbE#N#fbEbc.y.y#oaQ.X#t.P.P#t.P.X#k#7#c#c#c#D#F.X.sbw#w#Q#w.h.h",
"axaya5#jaV#s.ib2.A.J.V.H.C#I.H.D.D.Q#u.q.Q.Qb4#Zae#1..#1.ebo.y#FbC#r#R#k#b#F#F#F#o#D#k#k#r#c#cbH.ybD#Fa..Xa..X.X#D.T#7bH#7#r#D#Da..wbw.hbw#w#w#Q",
".Baya5#Qahbd#3.ia0.K#Kapbkbk.HbF.q.q.Q.q.q.mb4.mae#1...1.Mbo#F#rbDbIaRaq#kbXb0bC#ka7b0#r#cbububo#c#rb0#k#r#r#k#kbX#D.y.ybX#rbX#D.3aLbwbwbw#w.h.h",
"aOaO.G.U#QaP#3#3.0bP.I.abo.DbF#e#l.m#e.m.ma3.m#Zae#1..byb0#R#.ab#caaaqa#aa.a.I.aaR.I#..Z.J#Fbob0bob0#r#rb#aRaC.I.6.6#n.j.jauaL.j.j.s.h.h.h.hbw.h",
".YbZ.G.U.Ubl#vb2.F.c.8#0#0#g.1#q#q#q#g#gbrbrbr#0....bSabagan.o.fbm#z.s#V#w#Q.h#V#Q#V#w#w#Q#Q.UaNaNaN.s.U.s#Q#V#Q.U#Q#Q#Q#Q#Q#wbwbwbw.h.h.h.hbw#w",
"a5.GbK#j#j.U#d#v.FbT.8.E#0#0.E.E#g.E.E#q#g.E#g#0#q#1.l#Q#Q#Q.h#w#w#w.h#w.h#w#w#w#w#w#w#w.h#w#w.h.h#w.h#Q#Q#w#Q#V.U#Qbw#w.h.h#w.hbwbw.h.h.h.h.h.h",
"be.G#Q#Qbe.U.UaP#hbT.n#0#0a2.n#g#g#1#q#q#g.E.E#0#g#Waj#w.h#w.h#w.h#wbw.h#w#w#Q.h.hbw.h.h#Q.h#Q.h#Q.h.h#Q#Q#Q#Q#Q#Q#Q.h#w.h.h#wbwbwbwbw.h.h#Q.hbw",
".G.Gbe#Q.U#Q#QaNaG#Ya2.n#1#g#q#q#q#q#q#q#g#q#g#1#Wa6#Q#Q#w#w.h#wbw#wbwbwbwbw#w#w.h.h.h#Q.h#Q#w#w#Q#w#Q#Q#Q#Q#Q.h#V#Q#Q#w#Q#Q#Q#wbw.h.hbw.hbw.h.h",
"ay#9bebe#Qbe#Q#Q.UaV.L#Ya2#0#g#1#q#g#q#1#1#g#1#Waj#Q#w.hbw#Q.h.hbw.h#w.hbw.h#w#Qbw#w#w.hbw.h.h#w.h.h#Q.U#Q#Q#Q#Q#Q.h.h.h.h.h#Q.h.h#w.h.hbw.h.h.h",
"axay#9bebe#Qbe#j#j#QahagaS#4.1#q#q#q..bS#a#aaDbl.U#Q#Q#Q.h.h#Q.h#wbwbw#w.h.h.h#w#wbwbw.h#w.h.h#Q#Q#w#Q#Q#Q#Q#Q.h#w.h.h.h.h.h.h#Q.h.h#w.h#Q.hbw#w",
".#axay#9#Q.U#Q.h#Q#Q#Q#Q#jbbaf.l#W#a#WaDbU.2.U.U#Q#Q#w#Q#Q#Q.hbwbw.hbw.h.h#wbwbwbw#w.h#w#w#Q.h#w#Q.h#Q.U#Q#w#Q.h#w#w#Qbw#w.h.h.h#w.h.h.h.h.h.h.h",
".#.#axalbe#Q#Q#Q#Q#Q.h#Q#Q#Q#Q#Q.UbK.z.Ube#Q#j#Q#Q#Q#Q#Q.h#Q#Q#w.h.hbw#w.h.hbw.h#wbw.hbw.h#w#V.h#w#Q#Q#Q#Q#Q#w.h.h#w.hbw.hbw.h.h.h.h#Q.hbw.h.hbw",
"aB.#axax#9bebe#Q#Q#j#Q#Q.h#Q#Q#j.U#Q#Q#Q#Q#Q.h#Q#Q.U#Q#Q.h.h#w.hbw.h#w.h.hbw.h#wbwbw#wbw.h.h#Q#w#w.h#Q#Q#Q#Q.h#Q.h.hbwbwbw.h.h#Q.h.h.h#w.h.h.h.h"
};';
  return $buf;
} 

sub france_image {
  my $buf = '/* XPM */
static char *France[] = {
/* width height num_colors chars_per_pixel */
"    74    41      254            2",
/* colors */
".. c #220917",
".# c #2b8cd9",
".a c #ac8a3c",
".b c #97caeb",
".c c #7c2a0c",
".d c #9f8e7c",
".e c #114baf",
".f c #f4cb54",
".g c #c4ab64",
".h c #f4ea7a",
".i c #815637",
".j c #bc5510",
".k c #440a08",
".l c #4b4755",
".m c #d1c8ae",
".n c #cf8a14",
".o c #d58e79",
".p c #21296c",
".q c #b97419",
".r c #8c8664",
".s c #f2ac12",
".t c #d78749",
".u c #e1da77",
".v c #eaa84c",
".w c #d0e8ef",
".x c #cb6c51",
".y c #5e6784",
".z c #61ace5",
".A c #0f2988",
".B c #f4bc4e",
".C c #2268c6",
".D c #bbdceb",
".E c #a0b690",
".F c #ccaf82",
".G c #d69b1a",
".H c #090d6c",
".I c #d57919",
".J c #f1d6af",
".K c #303480",
".L c #429be3",
".M c #eaab7e",
".N c #e0c894",
".O c #b95e19",
".P c #314789",
".Q c #fcfba9",
".R c #f4d769",
".S c #bfc8c0",
".T c #d99845",
".U c #5c8ac9",
".V c #0d389f",
".W c #121c71",
".X c #f2d78b",
".Y c #494a73",
".Z c #a4beb4",
".0 c #7e726e",
".1 c #4b8acf",
".2 c #f2e89a",
".3 c #e2deaa",
".4 c #f8ecc0",
".5 c #496c9a",
".6 c #edb962",
".7 c #b97c2c",
".8 c #609cc0",
".9 c #df8c1f",
"#. c #e8af55",
"## c #8aafac",
"#a c #eabe80",
"#b c #8c3010",
"#c c #1a5cbc",
"#d c #c25b49",
"#e c #45374c",
"#f c #b4cbd7",
"#g c #dceced",
"#h c #eca014",
"#i c #1e2066",
"#j c #3894dc",
"#k c #bea482",
"#l c #ac4a1c",
"#m c #d07d5d",
"#n c #a56f1b",
"#o c #e89f49",
"#p c #c49a34",
"#q c #214896",
"#r c #1e2c7e",
"#s c #f1c990",
"#t c #f5f094",
"#u c #f4cd6c",
"#v c #373759",
"#w c #f1e16a",
"#x c #cfd7d7",
"#y c #6c7098",
"#z c #644b3c",
"#A c #bfad93",
"#B c #0c1d83",
"#C c #f3c063",
"#D c #c6634b",
"#E c #999fb1",
"#F c #b7752f",
"#G c #3478cd",
"#H c #c4e3ee",
"#I c #df8d32",
"#J c #f1ba3c",
"#K c #89a1b4",
"#L c #efc09f",
"#M c #dab544",
"#N c #d28865",
"#O c #0d2d97",
"#P c #d98032",
"#Q c #d69f66",
"#R c #213987",
"#S c #b13229",
"#T c #c4be7c",
"#U c #368dd7",
"#V c #f3e094",
"#W c #4c5690",
"#X c #b4aab4",
"#Y c #84bce7",
"#Z c #b8d5e4",
"#0 c #f1cf89",
"#1 c #a9d3eb",
"#2 c #c0513f",
"#3 c #322b49",
"#4 c #f0ab39",
"#5 c #f4a94a",
"#6 c #d3bb8d",
"#7 c #577dad",
"#8 c #6fa3bf",
"#9 c #f4b04f",
"a. c #6f2b0c",
"a# c #a01112",
"aa c #370a0a",
"ab c #9c6e64",
"ac c #c28d33",
"ad c #62210c",
"ae c #daa275",
"af c #345789",
"ag c #ac7a1c",
"ah c #a91f19",
"ai c #746e5c",
"aj c #ac4614",
"ak c #2c1e44",
"al c #a9611d",
"am c #3c6694",
"an c #7f6331",
"ao c #74622c",
"ap c #907a34",
"aq c #758fb0",
"ar c #684230",
"as c #7689a1",
"at c #878291",
"au c #b9c0ba",
"av c #4c4040",
"aw c #b09c50",
"ax c #5f5b7c",
"ay c #73b7e7",
"az c #fcfeb4",
"aA c #ab9e93",
"aB c #a07f46",
"aC c #716a7f",
"aD c #9893a0",
"aE c #594647",
"aF c #c46211",
"aG c #917131",
"aH c #cc8014",
"aI c #6a7fa0",
"aJ c #584244",
"aK c #8f5424",
"aL c #e79c32",
"aM c #2f296f",
"aN c #b68c4c",
"aO c #dca644",
"aP c #70acd4",
"aQ c #bf4434",
"aR c #f5e1b1",
"aS c #5c94d2",
"aT c #c97217",
"aU c #be382e",
"aV c #be9a5a",
"aW c #a49060",
"aX c #ceccbe",
"aY c #d79837",
"aZ c #474e8f",
"a0 c #acbbcc",
"a1 c #d8d8c8",
"a2 c #a47e60",
"a3 c #325fa4",
"a4 c #344187",
"a5 c #84aec7",
"a6 c #695d59",
"a7 c #d38b33",
"a8 c #50a3e2",
"a9 c #576a9c",
"b. c #5ca3dc",
"b# c #3472c4",
"ba c #a8a1ae",
"bb c #56110c",
"bc c #898d9f",
"bd c #4895cc",
"be c #8f6527",
"bf c #a9cde3",
"bg c #2c71c9",
"bh c #dcd18e",
"bi c #343f6c",
"bj c #cde2e9",
"bk c #695341",
"bl c #c0b39b",
"bm c #140e3c",
"bn c #dcda8c",
"bo c #d4827c",
"bp c #9c6d34",
"bq c #bfbea4",
"br c #1e4ca9",
"bs c #6c9cd8",
"bt c #5a4c5e",
"bu c #d9b766",
"bv c #717581",
"bw c #c87638",
"bx c #e6a474",
"by c #21316f",
"bz c #d07558",
"bA c #60708c",
"bB c #d98018",
"bC c #e6b47c",
"bD c #c4d2c0",
"bE c #4a608a",
"bF c #443e6c",
"bG c #947050",
"bH c #c77f34",
"bI c #dcae88",
"bJ c #6c8bb4",
"bK c #dcb884",
"bL c #c4beb4",
"bM c #d1d1a9",
"bN c #d09044",
"bO c #0c147b",
"bP c #d7a04b",
"bQ c #113fa3",
"bR c #7c7e74",
"bS c #a45311",
"bT c #397fd4",
"bU c #d68f67",
"bV c #ae2a20",
"bW c #3c3264",
"bX c #daa036",
"bY c #8c7e54",
"bZ c #cc6234",
"b0 c #d8ab64",
"b1 c #8ac3ea",
"b2 c #8c3e14",
"b3 c #2c66b4",
"b4 c #c4ddea",
"b5 c #3c4a74",
"b6 c #fce8a4",
"b7 c #cc5d4a",
/* pixels */
"#Zbj.w#Hbj#Hbj#H.D.D.D#Z#Zb4#Z#Z.D#Z#Zb4b4b4b4#Hbj#Hb4bjbj.wb4bjbj.wbj.w.w.w.w#g.w.w.w#g#g.w#g#g#g#g#g#g.w#g#g.w#g#g#g.w#g#g#g.wbj#g#g#g#g#g.w#g#g#g",
"#H#H.wbj#H.wbjbj#Z#Z#Z#Z#Z.D#Z.D.D#Zb4b4b4bjb4bjb4b4bjb4bjb4bj.w.wbjbj.w.w.w.w.w.w.w.w.w#g.w.w.w#g#g.w#g#g#g#g#g.w#g#g.w#g#g.w#g#g#g.w#g#g#g#g#g#g#g",
"bj.wbjbj#Hbjbj.D#Z#f#Z#Z.D#Z#Zb4b4.Db4.Db4b4b4.D#Hbjb4#Hb4bjbjbj.w#Hbj#H.w#gbj.w.w#g.wbj#g.w.w#g#g.w#g.w#g#g#g#g#g.w#g.w#g.w#g#g.w#g#g#g#g.w.w.w.w#g",
"bj#Hbj#Hbjbjb4b4.D#Z.Dbf#fbf#Z#Z#Z#Z#Z#Zb4b4b4b4b4b4b4bjbjb4b4b4bjbjb4bjbjbjbjbj.wbj.w.w.wbjbj.wbj#g.w.w#g#g.w#g#g#g.w#g.w#gbj#g.w#g.w.w#g#g.w#H#H#1",
".w.w.w.wb4#H#Z#1#fbf#Z#Z#Z#1#Z#Z#Zb4#Zb4#H.Db4.Db4b4b4bjbj.w#Hbj.wbj#Hbjbj.w.wbj.w.w#g#g.wbjbjbj#g.w#g#g.w#g#g#g.w.w#g#g#g#g#g#g#g#g.w#g#g#g.w.D#H.D",
"#g.w.w.w.w.w#fa5#KbJbJbJaqaqbJasasbJaI#7#7#7a9.5a9.5.5bEbE#WafbEbEaI#fbjbj#g.w#g.wbj.w#g#gbj#g#g.w#gbj#g.w#g#g#g#g.w#g.w#g#g#g#g#g.w#g#g#g#g#g#g.w.w",
".w#H#H.D#Hb4.y.U.1.1bdaSaSaSaSbs.1.1.C#cbr.V.V#O#B#BbO.W#B#BbO#B#B.W#Kbjbj#g.w.w#g#g#g#g#g.w#g#gbj#g#gbj#g.w#g#g.w#g#g#g#g#g#g.w#g#g#g#g.w#g#g#g#g.w",
".w#Hb4bj#Z#ZambTbTbT.1.1#GbRaq.Ubsb#.C.e#O.A#BbObObO.Wbp.W#RbObObO.Abcbjbjbj#gbjbj#g#g#g#g#g#g#g#g#g#gbj#g#g.w#g#g#g#g.w.w#xbM#g#g.w#g#g#g#g#g#g#g.w",
".w#Hb4#H.D#Za3#GbTbT.1bT#7.nac.U#G#c.e.V#O#B#BbObObObk.nbt#R#BbObObO.y.0.0abaVbKbqa1a1bD.mblaWbC#.b0.g.m.3aX#6.F#k#k.Taca7aY#9.6b0.F#AaDblblbD.w#g.w",
".wb4bj#Hb4#fb3#G#GbTbTbT.0.X.nat#c.C.e.V#O#ObObObO#B.g.T.7#i#BbObO#B..aabbaF#J.f.f#u.6#o#..vbP.R.f.f.f.B#5#IaL#IbBbB#IaL#4#9.R.f.R.f.R.7.R#0#a.d.w#g",
".wbjbj.wb4#fa3#G#G#Gbg.1#M.J.O.a#c#cbQ#O#BbObObO#BbF#V.t.saMbObO#B#B..aa#b.9#C.R.6#..T.6.B.B#0#u.R.f.f.f.B#4.9aL#4#9#4aL#4.f.R.R.R.R.R.B.f.X.R.d.w.w",
".w#H#H#H#Ha0a3#GbTbg.C#7#C.3.j.G.e.e.e.V#BbObObO#Ban.4bH.saE#B#BbO#B..bb#2#d#db7#d.xbzbw#V#0#u#u.R.R.f.f.B.B.B#4.s#4#4.B.B#ub6b6b6.R.R#u.B#u.R#A.wbj",
"b4#Hbj#Hb4#f#qbT#U#GbgaI#waR.j.G#ObQ.V#O#BbObObObOai.4a7#hbtbO#B#B.W..bbah#a.Q#m#dae#V#m#V#V#0#0#V#w.f.f.f.B#C.B.B#9#J#J#0.4.4.4.4b6#0#9#5#C#uaX.w.w",
".wbj#Hb4.D#Zbrbgbg#G.Cam.RaRaF.n#O.V#O#BbObObObO#B.YaR#P.s.pbO.W#B#B...k.O#QazbzaRbobx.obxbx#abx.X.6bN.v.R#..v.T.t.B#u.6#NbC.4.J.obIaR.6#o#9#ubM#g.w",
".w.w#H.w.D#Z.P.Cbgbgbg#q#MaRaFap.Va9aZbObO#rba#E#rby#V#IbX.Wata1bl.p..ad.j#Qaz.x#2aQ.MbzaQ#NaUbUbV.x#mbzbV#D#m#2bxaQ.o#D#mbz#D#2.o.x.o#s.TaL#o#CbL.w",
".D#H#Hb4b4.D#qb#aq.N#kb5.r#VaTa6bcaRaRaxbO#X#C.JaD#rbha7bp.Y#0.9.v.0.k.c#Paeaz#0#Lbn.J.o#2azbx#0.x#0a#.Q#2#D.Q#2.XbU#2#0ah.Q#Sb6ah#0#d#L#9bwa7.BaVbj",
"#g.w#H#H#H#ZaZb3bhaO#.#p.l#0aHaC#aaFa7aWbO#p.I.q#h.Yaw.I#zaAalarbSan.k#b#Ibx.Q.xbo#dbx.o.xazb7#daQ#d#D.Q#D#D.Qa#bC#Qae#aaUaU#2az#mbK.x#s#o.I#I#.aN#x",
"#H#H#H#Hbj.DbA.5.GaTan.qaJ#MalaNalav#3anbOagak.Hav.7aG.IaJac.p#B#3#z.kaj#Ibuazbz.4#L#N.o#D.QbzaR#2#0#S.Q#D#D#ta##abxb0.XbZb0#2az#SaUbV#sa7aT#I#9aNb4",
"#Hb4b4#Hb4b4bcam#naf.eby.i#n#n#n.WbO.H.H#B#vbO#BbO.iag.nbebk#B#B.AaMbb#laU#saz#maQ.ob7#L#2azb7bC#m.Qb7.Q#m#Daza##ab0#daz.x#dbV.2.M#d#d#.aTaF#I#9.a#x",
"b4.D.Db4.D.D#f#qaf#c#q#WaKaK.q.iaZbObObO.p#BbOa4bcaAaObN#MaDaZ#B#BbmadaQ#N#Nbzbz#m#DaR#s#2.obzbz#2#Q#d#m#d#d#N#S#m#mah.x#Q#dbzaQbU#D.t#o#P.I#h#9aVbj",
".D#Zbjb4b4.Db4.P#c.eb5.F#6bu.6bu.g#vbO.W#paMbO#rbvaWbXbX.Gap.l#B#B..b2#4#o#L.J.J#L#u.R#w.6#5.M.M.6bobx.M#L#9#.#9#o#I#4aL#P#5#C#s.M#L#0.v#I#l.I#oaY#x",
"#x#Zb4.D.w#Hb4as.e.e.A.AaBa7a7aE.WbObO.0.M.ibObO#BaCaH.9#p#B#B#B#Baa.O#.#C#0.J.J.X#u.R.R.R#L#s#C#o#5#9#C.X#u#u#u.f#4.B#9.B.B#9#s#u#u#u.6.TaFbB#4#o.S",
".w#Hbj#Hbj#H#H#Z#r.V#O#O#k#M.naG#BbO.WbubC#h.WbO#BbcanaVan#B#B#O.WadaTbH.T#C#C#u#u#u#Qbu#u#C#C#5aL#I#o#o#9#9#u#9#C#5.B#9#4#J.B.6.6#C.6#9#IaT.I.9#Ibl",
".wbj#H.w.w#H.wbj#7.V#Oby.lav#3#3bO.HaJ#wbC#h#e.H#B#v#i.l.AbO#O.A..ada.ada.bS.O#Fbpb0bG.7bN#F#F.OalalalbwbN#I#o.B#uaLaKaT#I.T.v#9#9.B#5#5bP#P.IaLaL#A",
"b4.w.w.w#H#H#H.D#X.A#O#BbObObObO#B.H#z.X#a#hbW.HbObO.A.A.A#ObQ#r#fb4bDbDaXbl#AaAbl#x.wbj.ma1bj#gbja1.m#Xbq.m#k#kbK.Fblbla2aK.T#.#5#9#4.va7#laT.9aL.3",
".w.w.w.w#H#H.D#H.w.Y#O#B#BbObO.HbO.H#e.RbC#h.W.HbO#B#B#B#O.V#casb4bjb4bj#g.wbjbj.w.w.w.w.w#gbj#g#g.wbj.w.w.wbj.wbjbj#x.w.wbDau.m#6#QacbNbHbH.T.T.N#g",
"#H.w.w#H#H.wb4#H#H#f.p#B#B.H#B#ybaaM#i#Jbuac.Wa9bLaA.K#BbQ.e#q.D#Hb4.w.wbj.wbj.w#gbj#g#g.wbjbjbjbjbjbj#gbjbjbj#Hbjbjbjbjbjbj.w#gbjau.S.Sbq.S.S#x.w.w",
"#H#H.w#H#H#H.D.D#Hb4bcbObObO#r#sbP#6.p#p#.aBa4#0#4.fba.AbQbQ#Ebjbj.w.w#g.w.w.w#gbjbj.w#g#H.D.D#Z.D.Db4#Hbjbjbj.w.w#Hbjbjbj#gbj#g.w.w#gbjbj.wbj#Hbj.w",
".w.w#H.w#H.w#H#H.Dbjb4bF#BbO#vbBaK#Fbtap.vbta2agaT.9aA.V.ebEb4bj.w.w.w#g.w#g.w.w.w.w.wb4#1#Y.za8#Yb1.b#Z#1.D.D.D#Hb4bjbjbjb4.w.w.w.w.w.wbj.wbjbj.w.w",
".w#H.w#H.w#H#H#H#H#H#H.S.WbO#va6#B#i#nav.G.lbe.p#i#nai.e#R#f.w.w.w.w.w.w#g.w.w.D.bbf#1.baya8.##U.##ja8ayb1b1b1.D.b#Y.Dbj#1.b.w.w#gbj.wbjbjbj.w.w.w.w",
"#H.w.w.w#H.w.w.D#H.w.wb4at#B#B#B#BbO#ear.qbG#3#O.A#R#q#q#Kbj#Hbj.w.w.w#g.w#gbjb1a8#j.Lb..L#j.#.#.#.#.#.##j#j.L.z.zb1#Y.b#Yb1#Y#Z#Zb4.w.w.wbj.w.w.w.w",
"#g.w.w.w.w#H.w#H#H#H#H.Db4aCbO#BbO.Pba.F#abK.FbE.ebQ#qbAbjb4.w.w.w#g.w.w.w.w.Da8#j.#.##j#j.#.8.E.8.1.##j.#.##j.L.bbf.b#Z#Zbjbjb4.D#H.Db4.D#Hbj.wbj.w",
".w.w.w#H.w#H#H.w#H#H#H.D#Hb4ax#B#BbibYac.n.naob5.e.eb5bj.w.w.wbj.w#g.w.w.w.w.b.#.##UaS.#.##8.u#w#w.ubh.Z###8.##j#Y#1#1.D.w.w.w.wbj.Db1b1b1.zb1#1#1.b",
".w#H.w#H.w#H.w#H#H.w.w.w#H#H#x.y#B#B#R.g#J#4bi.e.e#R#f.wbjbj.w.w.w.w#g.w#H#Hay#j.##Tbn##.E.u#w.h#w.h.h.h.hbnaP.#a8b1#1.D.w.w.w.w#1#Y.z#j#j#j.La8a8a8",
".w.w.w.w.w#H.w.w.w.w.w#H.w#H#HbjaC#B#Raw#M.aa6.ebQ#Ebj#H.w#H#H.w#g.w.w.w.w#Hay.L.#.E#w.u.h#w.h#w#w.h#w.h.h.h.Z.#.Lb1#1.b#1.bbf.bb1a8.#.#.#.#.#.#.L#j",
"#H.w.w.w.w.w#H#H#H.w#H#H.w.wb4bjb4#y.A#qai.V#RbraI#Hbj.w#Hbj.w#H.w.w#g.w#H.wb1#j.####w#w#w#w#w#w.h.h#w.h.h.h.2.8.#a8aya8a8a8a8.za8#j.#b..SbM#8#U#jbd",
".D.w.w.w.w.w.w.w.w#H#H#H.w#H#H#H.D.Dbcby.A#O#qaI#H.w#H.w.w#H.w.w.w#g.w.w.w.w#1a8.###.u.R#w#w.h#w.h.h.h.h.h#w.hbM#U.#.#.##j#j.##U.#.##jbM.2#t.2bM.3#t",
".w#H.w.w.w.w.w#H#H#H#H#H.w#H.w#H#Hbjb4a0bi#ras#H.w#H.w#H.w.w.w#H.w.w.w.w.w#H#1.L.##U.8.E#w#w.h.h.h.h.h.h.h.h.2.h.SaPbdbdb.a8.8aPa5.8.Z.2#V#t.h#t#t#t",
".w.w.w.w.w.w.w.w.w#H.w#H.w.D.w#H#Hb4b4.D#Zba.wb4#H.w.w#H.w#H.w#H.w.w.w#H.w#H.Day.#.#.#.#.E#w.h#w.h.h.h#t.h.h.h#t.h#t.3.3.2.2.2#t.4#t#t.2.h#t#t#t#t#t",
".w#H.w.w.w.w#H#H.w#H#H.w.w#H.w#H#H.D.w.D#H#H#H.w.w#H.w.w.w#H.w#H.w.w#H#H.w.w#H#1ay#j#j.##Ubn.h.h.h#t.h.h#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t#t",
"#H.w.w#H.w.w#H#H#H.w#H.w#H#H#H#H.w#H#H.w#H.w.w#H#H.w#H.w.w.w.w.w.w.wb1b1.w.wb1#H.Db1ay.L.###.h.h.h#t#t.h#t#t#t#t#t#t#t#t#t#t.2.Q#t#t#t#t#t#t#t.h#t#t"
};';
  return $buf;
}
 
sub banner_image {
  my $buf = '/* XPM */
static char *BloodRoyale_banner[] = {
/* width height num_colors chars_per_pixel */
"   581    83      256            2",
/* colors */
".. c #981008",
".# c #ab8373",
".a c #7b4b3b",
".b c #d4c0b4",
".c c #d78473",
".d c #b74c39",
".e c #aa1206",
".f c #e2dac2",
".g c #d8a393",
".h c #b86859",
".i c #936759",
".j c #7a3125",
".k c #c3a394",
".l c #f2bea3",
".m c #a72f1a",
".n c #efa493",
".o c #b39283",
".p c #984c3b",
".q c #d56959",
".r c #913020",
".s c #d8927b",
".t c #b7786a",
".u c #995b4b",
".v c #ebebdc",
".w c #bd3122",
".x c #eed0c3",
".y c #ce4d38",
".z c #bf8373",
".A c #8f4031",
".B c #dccebc",
".C c #dab3a3",
".D c #9b776b",
".E c #f8dccf",
".F c #a7200e",
".G c #a84030",
".H c #efb4a3",
".I c #ef9484",
".J c #b75d4e",
".K c #8a2111",
".L c #c76752",
".M c #c79383",
".N c #a84c3a",
".O c #e1c0b3",
".P c #a8685a",
".Q c #9a210f",
".R c #efc1bc",
".S c #90312e",
".T c #bf857d",
".U c #bc2012",
".V c #c87763",
".W c #a85b4b",
".X c #d7a59d",
".Y c #7b4032",
".Z c #d89694",
".0 c #e68474",
".1 c #a72712",
".2 c #edd1cc",
".3 c #e3dddc",
".4 c #cbb3a7",
".5 c #f7ddde",
".6 c #ab857d",
".7 c #a43539",
".8 c #dab5ad",
".9 c #f0b5ad",
"#. c #9c4030",
"## c #dfc2bc",
"#a c #8b5c4d",
"#b c #b84d46",
"#c c #c45c4d",
"#d c #eeaca0",
"#e c #d79b8b",
"#f c #a7413d",
"#g c #c8958d",
"#h c #a86964",
"#i c #a73827",
"#j c #b86964",
"#k c #984d45",
"#l c #98221c",
"#m c #f5ebdd",
"#n c #bf4130",
"#o c #dccfc4",
"#p c #c7695e",
"#q c #d78c7a",
"#r c #a74d46",
"#s c #c08c80",
"#t c #d57967",
"#u c #913723",
"#v c #aa786a",
"#w c #d9aca0",
"#x c #c4ab9f",
"#y c #efc7b4",
"#z c #bb9b8f",
"#A c #894b3b",
"#B c #7b392c",
"#C c #a75d55",
"#D c #b87d75",
"#E c #efc9be",
"#F c #c6796f",
"#G c #a81909",
"#H c #9a5d55",
"#I c #8f443d",
"#J c #e4e4d3",
"#K c #b8605d",
"#L c #80201c",
"#M c #90382f",
"#N c #844031",
"#O c #fcd2c2",
"#P c #c18b74",
"#Q c #f7e3d3",
"#R c #d9ab94",
"#S c #9b6f60",
"#T c #cd5c4a",
"#U c #b4200e",
"#V c #ee9c89",
"#W c #b42717",
"#X c #b75548",
"#Y c #d4c7bc",
"#Z c #b44130",
"#0 c #fcb5a2",
"#1 c #ab8c80",
"#2 c #8b5447",
"#3 c #e49484",
"#4 c #e4b4a3",
"#5 c #e1c7b4",
"#6 c #e4d0c6",
"#7 c #c77163",
"#8 c #aa7d75",
"#9 c #b4301d",
"a. c #9a2812",
"a# c #e67d70",
"aa c #be3924",
"ab c #b28a74",
"ac c #b4523c",
"ad c #812a14",
"ae c #d79d94",
"af c #e78d80",
"ag c #e4e4dc",
"ah c #81271f",
"ai c #fc9e89",
"aj c #e4cebc",
"ak c #cc4335",
"al c #dc5e54",
"am c #9b190d",
"an c #7c5448",
"ao c #d56f5e",
"ap c #fcd5cc",
"aq c #e4b8ae",
"ar c #fcb8ae",
"as c #b4453d",
"at c #d57d75",
"au c #b76f5b",
"av c #98533b",
"aw c #cd543e",
"ax c #c57054",
"ay c #c99b83",
"az c #a8523c",
"aA c #a86f5c",
"aB c #be2815",
"aC c #f6e5dd",
"aD c #e0c9bf",
"aE c #c89c90",
"aF c #a87066",
"aG c #b77166",
"aH c #985448",
"aI c #99281d",
"aJ c #a75449",
"aK c #ecdbcf",
"aL c #9c685a",
"aM c #843020",
"aN c #cca497",
"aO c #fcc0b2",
"aP c #fca294",
"aQ c #bc9487",
"aR c #fcac9e",
"aS c #ccab9f",
"aT c #84392d",
"aU c #b4180b",
"aV c #9c443d",
"aW c #84443d",
"aX c #b48373",
"aY c #c44d39",
"aZ c #e4a493",
"a0 c #9c3020",
"a1 c #cc8473",
"a2 c #a7281d",
"a3 c #c44c44",
"a4 c #e49c8a",
"a5 c #b43926",
"a6 c #d68d85",
"a7 c #cc8c80",
"a8 c #e4aca0",
"a9 c #8a4d44",
"b. c #fcc9be",
"b# c #9c3930",
"ba c #ed9d95",
"bb c #c45548",
"bc c #b48c7f",
"bd c #cc3624",
"be c #e49d95",
"bf c #ece5dc",
"bg c #8c291e",
"bh c #eaf2de",
"bi c #7b4636",
"bj c #ccbaaf",
"bk c #8b6256",
"bl c #f4f2e4",
"bm c #bf4636",
"bn c #cc624e",
"bo c #b41204",
"bp c #fcc1bd",
"bq c #9c302c",
"br c #cc857d",
"bs c #e4a59d",
"bt c #b4857c",
"bu c #9c3723",
"bv c #fcc7b3",
"bw c #ece4d3",
"bx c #cc8b73",
"by c #e4aa93",
"bz c #8c2913",
"bA c #ecdedc",
"bB c #8c1f1c",
"bC c #c4533c",
"bD c #c46253",
"bE c #e4d6bc",
"bF c #b87e6c",
"bG c #99624c",
"bH c #efd6c4",
"bI c #904633",
"bJ c #dbbaa3",
"bK c #9c7e71",
"bL c #a94633",
"bM c #f0baa3",
"bN c #b76252",
"bO c #c77e64",
"bP c #aa624a",
"bQ c #edd6cc",
"bR c #a93a39",
"bS c #dabaaf",
"bT c #f0baae",
"bU c #a5463e",
"bV c #dcd6c9",
"bW c #d67e6c",
"bX c #aa7e6c",
"bY c #a76257",
"bZ c #c67e71",
"b0 c #996256",
"b1 c #d4c2bc",
"b2 c #d6857d",
"b3 c #e4dcd2",
"b4 c #c3a49c",
"b5 c #f0c0b2",
"b6 c #a63026",
"b7 c #eea59d",
"b8 c #b4948d",
"b9 c #d79488",
/* pixels */
"#6#oaDaD.b.b#6b1#Y#6bjbj#YaD.baD#6bSbSaDbjbSbQaD.baDb1bjbEb3#Y#Y#ob1###6##aDaDb1##aDaD##.2aD##aD#6.B.BbV#Y.b#6ajbE.E#o##aD.2.2bQ#6#5aD#6aj.B#6.BaDaD.b#5bE#6aD#6ajaj.EaKajajaKaD#6aKbE#6#6.B#6.xaD#EbH.x.x.x.x.xaDbHaKbEbEbEb3bE#6#6aDaD#o#6aDaD.B#6aKaDaD.B#6#obE#o#ob3.B.B#o#o.B#6bE#o#6aKaD#6#6aDaDaKaD#Y#6aDaDbEb1aDbA.2#YaD#6#6aKb3.b##aKb1aD#6aDb1#6#YaDaK#6aD#6aDb1#6#6b1aD#oaD#o#6aD#6#6aDaD#6aDaDb3aDaDaK#oaD#o###Y#6#6#6bQ#6#6bQ#6#o#6#6#6bQ#6aD#obQ#o#6aK#oaD#oaDaD#6bQ#6#6aD#6#6aDbQ#6#5aD#6#6.faKbEbQ#6#6#6ajbE#6#6#6#6aD#6#6#6#6#o#o#6#6bEbE#6bE#oaD#6#o#6.2aDaDaDaD.2bQ.2#6.2#6.2aDaD#EaDaD.O###6aD.2aC#6#Y#o#Y#ob3##bS#6aD#YaC#o#Y#o#Y#Ybwaj#Y#6aDb1bQ#6b1aDaDaD.2bQaDaDbSbjaD.2#Y#Y#o#Y#obV#o#o#6#Y#Y#o#o#o#o.b.bbE.2#6bQ#ob1#obEbVb3#Y#YbVbV#o#o#6#5###6aDaDbE#Y#YbE#o#ob3#6#o#o#6bQbQ#6#6aKaKbQ#6#6aDaDaK#6#6#6aD#6.E#6bQbQaD#oaK#6aDaKbQbEbA#6bQbA#6#6bQ#6bQbQ#o#6.EbEbQbQ#6#6bQbQaKbQbQaK#6bQ#6#6aKaK.2#6#obQbQ#6#6#oaD#6bQaKbQaKbQ#6bQ#6#o##aDbEaDaD#6#oaD#6aDaD#6aDaD#6aDaD#oaD.B#6aDaD#6#6#6aDaD#o#6#6#o####.baDaD.baDaD#YaD#o.BaD#o#Y#Y.Bb1aD#o#Yb1#6aD#oaD#Y#o#o#o#o#oaD.baDbE#oaD#6#YbjaD#YaD#6aD#Y#oaD#6bQ#6#YaDbQ#6aDaDbj#6bQaDaD#o.b.b#6.b.b#6aD#YaD.b.b#6aDaD#6aDaDaDaD.baD",
"aD#6#oaD#Y#o#o.baDaD#YaD#YaD#6aDaD#YaDaDaD##aDb1aD#o#Y#YaD#o#Yb1#Y#6##aDaDaDaD##aD####aD####aD#Y#5bE#Y.B#5#Y#YaD#6aDaD.xaD#5.2#6aD.B.B#Y#5.Bajaj.B#Y#5#oaD#6#6ajajbH#6bH.f#5#6.faj#6bE#6bEbQbE#6aD.2ap#E.2.2.x.EajajbH#6#6bEbHaK#6#o#o.B#6#oaD#oaD#6bQ.B#6bQaD#6bE.BbVaK#o.B.B#o.B#o#6#o#6#6#6aD#6#o#6#6aDaD#oaD#6#6b1aD#6#6#6#6#o#6#6b3aD##b3aDb1aDaD#6#6aDaD#6#6#6bV#YaD#oaD#oaDaD#YaDaDaD#YaDaD#o#oaD#YaDaDaD#6#oaDaDb1aDaDaD#6bV#6#6aDaD#6#6aD#6#6#6#oaD#6#6#o#o#o#Y.BaDaDaD#6aD.xaD#EaD#6.2#6.B#6#6#obH#6#obE#6.B#6#o#6#6aj#6.2aDaD#6#6#oaDaD#o#6#6.B#obQ.BaD#6aD#6#6aD##.2aD#6bQaD#6.2aD#6bQaDaDaD.xaDaD#6#E#6aD#o#o#o#o#o#6aD###6#o#6#o.B.B.B.B.BbE#6#6#6#o#o#oaD#6aDaD#6aD#6aD##aDaDaD#6#Y#Y#o#o#Y#o#oaD#6#o#oaD#o#o#o#YaD#6#o#oaD#o#oaD#obV#o#YbV#obVbV#YaD.xaDaD#oaDaD#6#o#Y#o#Y#o#obE#6#obQ#o#6#6#6#6bQ#6#6#6#6bQ#6aD#6#6#6#o#6#6#o#6#6#6#6#6#6bQbQaD#6#6#6bQbQ#6aDbE#6#6bQ#6.2aK#o#6bQ#6#6aK#6#6aK#6#6aK#6bQbQbQ#oaD#6#6#6.2#6#6bQ#6#6aKbQ#6#6#6.2bEaDaDb3aDaDbQ#6#6aKaDaDbQaD#o#6#oaD#6#oaD.BaD.BbVaD.B#YaD#o#6#6aD.baDaDaD.xaDb1aD#YaDbE#YaD#6#Y#Y#o#Y#o#6b1#Y#6#YaDaD#YaD#oaDaDaD#o#Y.b#6#obj#YaDaDaD#Y#YaD#YaD#YaD#6#oaDaD#oaDaDaDb1aD#YaDaDaDaD.bb1#oaD.b#6aDaDaD.b#YaD#YaDaj#YaD#5##aDaD",
"#o#6#o#6#YaD#6aD#Y#6aDaD#o#o#oaD#oaDaD#6aDaD#oaDaDaDaD#Y#Y#Y#Yb1#Y#oaD#oaDaD###Y##aDaD#oaDaDb1aD#Y.B#5#5#Y.b.B#5aDaD#YaDaDaD#6#6#6.B.B.BaD#Y.BaD.B.B#YaD#6#o.BaD#6#6#6bE#6#obEaK#6#o#6#6bQbQ#6bEbQbQ.2aD.x.x#6#6aDaD#6aDaD#6aKbQ#6aj#6#6#6#6aD#oaDaDaKaD#obQ#6#ob3aD#oaK#6aD#o#oaDaD#6aDaD#6aDaD#6aDaD#o##aD#6#6#6#6b1aD#o#6#oaD.2#6aD#6#oaD#oaDaDaD#YaDb3aD#YaD#oaD#oaDaD#oaDaD#Y#Y#oaD#oaDb1aD#o#6#6#oaD#o#o#o#6#oaD#Yb1aD#Y#oaD#oaD#6#o#oaD#o#6#o#6#6#6#o#6#6#6#o.BaD#o#oaD#o#6#6#6aD#6#6aD.2#6#6#6#6#6bEaDaD#6aD.B#6ajaD.B#6aDaD#6aDaD.2aDaD#Y#6#6#6aD#oaK.Baj#6#6aD#6aDaD.2aD.2.2aD#6#6#6#6bQ#6aD#6#6#5aDaDaDaD#6aDaD#6aD#o.2aDaDaD#6#6#o#Y#Y.B.B.B#o.BbEbQ#6#6#6b1###o#6.2aDaDaDaDaD#6aD#6aD#Y#o#YaD#6aDaDaD#EaD#E#6#E#6aD#o#oaD#o#oaDaD#o#o#6#o#YbVbVbVbV#o#6#6aDaDaD#Y.B#o#o#6aD#Y#o#o#6#o#6#6#6#6#6#6#6bE#6bQ#6#6b3.2#o#6#6#6#o#6#6#6.2#6#6#6aDb3#6#6#6aD#6#6#6#6#6#6#6bQ#6aK#6b3bQaD#6b3#6#6bQ#6#6aK.2#6aKbQ#6bEbQ#6aD#6#6b3bQ#6#6aK#6#6aK#6aDb3#6b3.5aDaD#6aD#oaKaD#6bQaD#oaK#oaDbQ#6aD#6#6#6#6aD#o#6aDaDaD.B.B#6bE#Y.b#5aDaD.2aD###6aDaD#6aD#YbV#Y#5#oaDaD#6#Yb1#6aDaD#YaD#YaDaD#ob1#Y#o#YaDbjbS#Y#Y#Y.B#5#YaD#Y#YaD#YaDaDb1b1aDaD#YaDb1aDaD#YaD#Yb1.baD#6.baD#6aD#Yaj.b.bajaD#Y#6aDaDaDaDaDaD",
"#oaDaD#6#oaD#o#YaD#6#ob1aDaD#YaD#6.baD#6#6aD#6aDaDaD#YaDaDaD#o#Y#oaD#o#6aD#o#oaD#Y#o#o#o#oaDb1#o#6ajaD.B#5#5#6#o#o#6#oaD#o.2b3#6#6#o#o#o.BaD#oaDaD#6aDaD#6#oaDaD#Y#6bEbEaD#6bEaD#6b3aDaD#6#o#6bQbQ#6#6#o#6#6#6aD#YaD#YaD#6#6aD#6#6aDaDaDaDaDaDaD#oaDaD#6aDaD.2bQaD#YbE#o#o#oaDaD#6aDaD#6aDaD#6aDaDb1aD#6#Y#o#6#6#6#6#oaD###oaDaD#6#o#o#6aD#Y#6#YaD#o#YaD#6#Yb1#6#oaD#6#YaD#o#oaD#YaD#6#6#6#o#Y#o#6#o#o#o#Y#6#6#6b3aDaD#6#YaD#6aD#o#6#o#o#6#6#oaD#6#o#6#6#6aD#6#o#6bE#oaD#6#6#o#6#6aD#6#6aD#6#6bQbEaD#6bH#6#6#6.BaDaj.2ajaD#6aDaD.2aD##.2aD#6#6aD#6aDaD#6#6#6.x.2#oaDaD.2aK.2aDaDaDaD.2aDaD#6aD#6#o#o#6ajaD.2#EaD#E#E#E#E#####EaD#E.2#EaD.xaDaD.B#Y.B#Y.B#oaDaD#oaDaD#6#ob1#6#6#6#6#6#ob1aDaDaD#6#o##aDaD##.2#E###E.R#E#E#EaD#E#EaD#6#obEb3#YaD#6#6#6#6aD#oaD#6.2bQbV#5#Y#6.B.B#6aDaDb3#6#6.2aDaDaD#6bQbQ#6#6#6#6.2b3#6#6#6bQbQ#6bQaD#6aK#6#6aK#6#6aK#6#6bQ#6#6bQaD#6bQ#6#6b3#6.2bA#6#6.5#6#6bQ#6aD#6b3aD#6aK#6#6bA.2#obQ#6aDaK#o#6bQaD#6#6#6aDb3bQ#6#6#6aD#6aDaD#o#YaD#6aDaDaDaD#YaD#6aDaD#6aD#Y#6.B#o#6bE.B#YaD#o#o.b#Y#oaDaD#6.b##.2aD##aD##aDaD#YaD#o#5#YaDaD#Y#YaD#YaDaj#oaD#oaDb1aDaD#Y#6.baD.b#YaD.bbj#5#Ybj.b#Y.baD#Y#5aD.b#Yb1aDb1b1#oaDb1.bb1b1aDaDbjaDaD.bb1aD.b#Y.baDb1.bb1.b.baD.bbjaDaDaD#YaD",
"aD#oaD#o#6#oaDaD#o#o#6#o#YaDbQ#oaDbE#6#6bEb3###ob3#6#6bQaDb1bQaDaD#6#oaD#6#6#o#6#6#o#o#6aD#Y#o#6#6.x#5aD#6ajaj#6#6aD#obV#Y.BbV#o#Y#6aD#Y#Y#YaD#o#6aD#Y#6aDaD#6aDaD#6#o#6b3b1#o#6aD#6#o#o.2#6#oaD#obVbE#o#o#oaD#oaDaD#Y###oaDaDaDaD##aD##b1##b1####aDaDaD##aD#6#6aDaD#o#6#o#6aD#o#6aDaDaDaDaDaDaDaDaDaD#6aD#6#6aD#6aDaDaDb1aD#6aD#Y#6#6#6#o#6#6#oaD#o#o#o#o#6#o#6#6#6#oaD#6#oaDb3aD#ob3aD#6bA#YaD#6b1aD#6aDaDb3#6#6aD#o#oaDbV#o#6#6aDaD#oaD#Y#6#o#6b3aDaDb3b1b1#6aD#o#6aD#6bE#6aDaD#o#6#6aD#6#6b3aD#6#6#6#6bQaDaD#6aD#6.2#6#6aDaD#6aDaD##aDaD#6aDaDaDaD#6aDaD.2aDaDaDaDaD#6#6aD#6aDaD#6#oaD#6#oaD#6#Y#obE#o#6aD#y#E#E.R.R.R.Rb..R.R##.O#E.xaDaj#6aDaD#6.B#o#YaD#6#Y#Y#o#6.2#YaDb3aD#6bQaDaDb3#####6aDaD#6aD#E#6###E.2.2#E###E.2#EbQ#6aDbQaD.2aKaDaD.2aD#E.2##aD.5#6aD.fbE#obE#o#6bQ#oaD#6aDaD.2#6aD#6bQ#o#6#6aDaD#6aDaD#6#6#o#6aD#obQ#oaD#6#6#6bQ#6#6#6#6#6#6#6#oaDaDaD#6bQaDaD#6#6#6#6#oaDbQaD#6#6aD#6aDaD#6#6aD#6#6aD#oaDaD#6aDaDaDaD#oaDaDaD#6aD#6aDb1aDaDb1aDaDb1b1aD#YaD#Yb1aD#YaDaD#YaDaDb1aDaDaDaDaD#YaD.B#o.B.baD.BaD#o#o####aD##aDaD##aDaD##aDaD#YaDaDaDaDaD.B#Y#5#oaDaD.B#5aDaD.b##ajaDaDaD.b#Y#Y.b#YaD#Y#5#Y.bbj#Y.bbj.baD.b.baDaD.baD.b.b#Y.baDaDbjb1#6.b.baD#Y##aD#Y###YaDb1b1aj#Y.b#o##aD#6#5",
"aDaD#6b3aDaDaK#oaDbQbEaD#6#6bVbEbQ#oaDb3aD#o#6.2aD#6.2aD.2aD.2.2aDaDaD#6aDaD#6#Y###o#o#6b3aD#Y#6aDaDaD#E##aD#6#6#o#o.B.b#Y#Y.B.B#o#Yb1aDaD#YaDaDb1aD#####oaD##b1aDaDaDaD##aDaDaD#6aDb1aD.2#######o#o#o#Y#o#Yb1#6#Y###ob1#####6.2####aDaD##aDaDaDb1##.2##aD#6aDaD#6#YaD#6#6#6#6#6#6aDaD#6aDaD#EaDaD##aD#6aD###6##aDaDaDaDaDaD#o###6#6#o#6#oaDaDaD#o#6aDaD#6aDaD#6#6#o#6#oaDbVaD#oaDaD#oaD#o#6#o#YaDaD#o#6#o#6#6#6#6#YaDbVaDaD#6aD#o#oaD#o#6#6#6aD#oaDaD#o#6aDaDaDaD#6#oaD#6#6#6b3#6#6bQ#o#o#6#o#6#6aDaD#6aD#6aDaD#6aD#6bQaDaD#6#6aDaDaDb1aDaDaDaDaDaD#EaD##aD.2aDaDaD#YaD#oaDaD#6#o#o.2#o#6#6#6#6b3aD#Y#6aD#5#E#E#EbT.X#s#D#D#D.z#Dbt#s#w#y##.x#5##aj#6.2#6aDaD.2#oaD#6#o#Y#6#o#6#6#6#6#oaD#6aD#6#o#o#o#o#6#6#6##.2aD#E.2#EaD.2.2#EaD#E.x.2#EaD#E.x.2.2aD#EaD#E.2bH#o#Y#Y#o#YaD#6aDaD.2aD##.2aDaDaDaD#6#6aDaD#o#6#6#6#6#oaDaD#oaD#6aD#6aD#YaD#6#6#6#6aDaD#6aDaD#6b1aD#oaDaD#oaD#oaDaD#6aD#o#6aD#o#6aD#6#6aD#o#6aDaD#6#oaD#YaDaDb1aD#o#6#6aDaD#6aDaD#oaDb1aD#YaD.2#oaDaDaDaD#6aDaD#6#YaD#6#oaD#6aDaD#oaD#o#oaD#o#6aj#oaDaD#6#o#6aDb1aD.2aD.2aD##aDaDaD#6aDaDaDaDaD#6.BaDbEaDaD#6aD#5aD#6.x.xaD.xaDaDaD.BaD#Y.b#5#YaD#6#Y#Y.B.bbjaD#Y#6#6b1aD#o#YaDaDb1aDaDaDaDb1aDaDaDaD#YaD#6.baD#6.baD#6aD#5#6aDaDaD#6aDaD",
"#oaDaDaDaDaD#oaD#Y#oaD#6aD#oaDaD#6#6#6.2#oaD#6aD#6.2aD.2.R.2.R####aDaDaDaDaDaDaDb1b1###o#o#Y#Y#YaDaD##aDaD##aDaDaD.BaD#Y#Y#Y.B#Y#Y#Yb1aD####aDaD############aD####aDaD#6aDaD.2.2aD.2#####6##aD#6aD#6b3aD#6#6aDaDaDaDaD##.2aD##.2#6aD##b1aDaDaDaDaD#6#6aDaD#6.2bA.2aD#6#6#o#6#oaD#6#6aD#6aD#6aD#6.2#6aDaDaDaDaD#oaD#6aDaDaDaDaD#Y#oaDaDaD#oaD#YaDaD#YaD#Y#6#YaD#oaDaD#6#6aD#6#o#oaDaD#o#o#6#6#6aD#YaD#oaDaD#o#oaDaDaDaDaD#Y#o#6#oaD#oaD#oaD#6#6aD#oaDaD#o#6#YaD#6aD#oaDaD#6#6#6bQ#6b3b3#6#o#6#o#6aDb1aDaD#o#6#oaD#oaD#o#6#6#6aD#o#6aDaDaDaDaD#6aD.2.2#6#6.2aDaDaD.2aDaDaDbQ#6aD#oaD#6bA#6#6bQ#6bQbQaD#5aj.x.x.RaE#sae.Z.T#DaG#F#D.t#s#saNaNbc.CaD.OaD.xaDaDaDaD.2aD#6aD#o#6#6#6#6aj.Baj.x.2.2.xaDaDaDaD.xaDaD#E.O###E.R##.R.R#E#E#E.R.R.R.R.R###E#E#E.2#EaD##aD#6aD#Y#oaDaD#Yb1aDaDaDaDaD.2aDaDaDaD##aDaDb1aDaDaD#6#oaD#6aD#o.2aDaD#o#oaD#6aD#oaDaD#o#6aD#o#oaD#oaDaD#oaD#oaDaD#o#6#YaD#6#6#6#6#6#6#6#6#6#6bQ#6aD#6#6#6#6#6aD#oaD#6bQ#o#6#6#o#6bQb3aD#oaD#6#6#o#6b3#6b3#6#6#6#6aD#6#6#6b3aDbQ#6#o#6#6#6bEaK#6#6#6#6bE#6#o#6aj#6bEaD#6bQaD.2aDaD#6aDaDaD#oaDaD#o#6#o#o.B.B.B#o.BaD#6aDaD#6aDaD#5##aD#6#oaD#5#YaDaD#YaD#Y###Y#5aD#Y#5#YaD#Yb1##aDaDb1aDaDb1b1#Y#YaD#Y#YaDaDaDaDaDaD#Y.baDaD#YaD.b.b.BaD.BaD.b",
"aDaDaD#Y#Y#YaDb1aDaD#YaD##b1#YaD#o#oaDb3aDaDaDaDaD#E#E###E#E.R.R.R#E.O###5#######5.OaDaD###5aDaD##.2aDaDaDaD##aDaDaD#obE#Y#Y.f#5aD#EaD##aDaD####.2.R##.2.R.Rb.#E##.2.2.2.2#E.2.2.R.R#E#E#E#E.2#E#E.2.2#E.x.2aD.2##aD.2aD###6.2.2.2aDaD##aD#6aD#6aD#6.2####aD#6#Eb3aD#o#6aD#oaDaDaDaD#6b1aD#o##aD#6aDaDaDaDaDaD#####6aDaDaDaDaDaD##aD#oaDb1aDbVaDaD#YaDaDaDaD#o#6aD#o#6aDaD#oaD#6#oaD#6#6#6#6aD#o#oaD#6#oaDaDaDaD#o#oaDaDaD#6#6aD#6aDaD#6#6#obQ#6aD#6aDaD#6aD#o#6#oaD.2#6aD#o#6#o#oaD.3#o#o#6#6#6#YaD#o#o#6#6aDaD#6#oaDbA#6#obQ#6aDbV#Y#oaD#6#6aD#6#6aDaD#6aD#6aD.2bQaDaD#6#6#o#6aDaD#6aDaD#6#6#6.2#5#5aD#w.M#g#s.Tae.ZbZ.tbZ#F.tbr.XaqbTaE#saQaQ#w#yaD#EaDaD##.2aDaDaDaD.2aD#5aD#5aD#E#5.x#EaD#E#E.O.O.OaNaQ#s#8#D.T#D#8#Dbt.Tbt#D.t.t#D#Dbt#gaEaSbS##aD.2aDaD#6##aD.xaDaDaD##aD.2aDaD#6aDaD#6#6aD#Y#oaD#o#6#6#obQb1aD#6aDaD#6aD#o.2aD#o#6#oaD#6aD#6#6#6#6#6#6aD#o#6#6#6bQaD#o#6aD#obQ#6#6bQ#6#6#6aD#6bQ#6.2b3#6#o.2b3.2#6#oaDaDb3#6#6bA#6#6#6#6#6.2#6#6bQ#6#6.2#6aD.5#6#obQ#oaDbQ#oaDbQ#6aDbAaD#6bE#6#6#6#6#o#6#6#6aD#6aD#o#6#6aD#6aD.2#6##aDaD##aD#6#YaD#oaDaDbE.B#Y#o#Y#oaDaD#6#6b1###5aDaDaDaDaDaD#YaD#Y.b.b#Y#5.b.b.b.baD#YaDb1b1##b1b1#YaD#Yb1b1.bb1##b1aD.b.baD#Y.baD.b.b.bbj#5#o.baD#Y.baDaDaDaD.b",
"aD#oaD####aDaDaDaD#oaDaD#YaDaDaD#oaDaD#6aDaD#oaD###E##.R.RaqaE#Dbt#8#8bt#saN.Ob5##.x#5#5.xaDaj.x#6#6#6#6aDaD#6#6#6#6.xaD#5bH.x.x#E##.R#E#E#E.R.Oaqaq#w#g#sbtbtbtbt.6.6bcbt#s#sbtbtbtbcbc#gaE.8##.R#Eb.b5#y#y#E.R###EaD##aD##.2bQ#6#6aDaDaD#6aDaDaD#6#6aDaD#6aD#o#6##aD#o#oaD#Yb1#Y#YaDaDaDaD#Yb1aDaDaDaDaDaDaD##aD#6#6aD#6#6aDaD#Y#6aDaDaDaDaD#oaD#6aD#Y#6aDaD#6#6aDb3#6aD#6#6aDaDaDaD#6aDaD#6#6#6.2bQ#6#6bQ#6#6.2aDaD#6aDaDbQ#6#6#6#oaDbQ.2#6#6#6aD#6b3aDaD#6aDaD.2#6aD#6###o#6#o#ob3aD#Y#6#6#6#6#o#Y#6#o#o#6#o#6#6#obA#6#6b3#o#o#o#o#Y#Y#oaDaDaD.2aD#oaD###6#6#6aD#6#6#6#6aDaD#YaD#o#6aDb1aD#6#E##.R#wbt#8.g#dae.zbY.Pau.t.zaubYb0.t.gbTb5aE#v.DaN#E#E.2aD##.2.R###E#E.R#5#E#5#EaD#5.CaQ.#.##saEaN.8aq.X#gaQ#D#D#D#8#D#D#D#D#D#D#D#D#D.T#saQaN#w.8aqaN.6.6b4aD.x#E#EaD#E#E##.2.2aD.2aDaDbQbV#o#6#o#6bQ#6#6#6.2b3.2#o#6#oaD#6#6#6#6bQ.2#6#6#6#o#o#6#oaD#6#oaD#6#oaDbQ#oaD#oaDaD#6aDaD#6#6#6#6aDaD#o#6#6#o#6#6aD#6#6aDb3aDaD#o#oaD#6aD#6bQ#o#o#6#oaDaDaDaD#6#o#6aDaD#6#6aD#6#oaDaDaD#oaD#6#6aDaD#6#6.2bE#6aD#6#6aDaDaD#Y#6aD#6#6aDaD#o#6#6aDb1#Y#oaD#oaD#Y#oaDaDbVaD#Y#o#YaD#o#Y#oaDaDaDaDb1aDaD##aDbjb1aD.b##aDaDaD#Y##aD#Y#5#Y##aDaD#YaD#6aDaDaD#YaDb1aDaDbjaD#oaDaD.b#YaD#YaDaD.baDaDaD#Y##.baDaDaDaDaj",
"bQ#6aD#6aDaD#6aDaD#6.2#6#6aDbQ#6aDbQ.2.2.2aD##aD#E##aN.6bt.X.X#D#D#D#8#D#gae.X.MbtaE.O#E#y#E#E#EaD#6aD#oaDaDaDaD#5aD#E.x##b5.x#5b5b5.C#gbt#8bt.M.X.Xae#gbt#DaX#v#vbtbF#vaXbt#8#D#D#vbt.TbcaE#w#w.g#g#sbt#8#saNaq#y#E#E###E.2.2.E.2aD#oaDaD#6aD#6#6.2bEaDaD#6aD#6#6#Y#6bEaj#YaD#Y#6#Y#YbE#oaD#6#obQ.2aD.2#6aD#6aDaD.2.2aD.2#6bQaDaDbQbQ#6bQ#6aD#6#6aD#6#6bQ#6#6#6aD#6.2#6aD#6aD#6#oaD#6aD#6bQ#6aD#6aD#6#6aD#6.2aDaDaDaDaD#o#6#6#6#6#6#6#6#6#6.2#6#6bQaD#6#6aDaD#6aDaD.2b1aD#6#o#o#o#o###o#6aD#6.2aDaD#o#o#6#6#6#6aD#o#6#6aD#oaDaD#o#o#Y#Y#o#6aDaDaD#6aD###o#o#o#o#oaD.2aD#6aD#o#6#o#YaD#6aD##.O#E.xbT#g#haHa7.RaOa6aH#IbP.tbOaZ.H#gaA#A#h.gb5.R.Xbkbt.x.R#E#E.2#E#E#E#E.R#E#E#wbc.#aQ.C#w#gbt.6#saN#waqbT#w#g.T#D#8#DaG#D#D#D#D#D#D#Dbt.T#gaEaS#waq#Eaqb4.6.6#g#waEbtaN.R#Eb..R###E.2###o#o#obVbV#YaDaD#6#6aD#o#6#6aD#o#6#YaD#6aDaD#6aD#o#6aDaDaDaDb1##aD#Y##aDaDaDaDaDaD#o#Y##aD#oaD#ob1#o#6#YaD#oaD#o#6aDaD#oaDaDaDaDaDaDb1aDaDaD#6#6#6#6aDaD#oaDaDaDaD#o#6#6#6#6aDaD#6#oaD#6#oaD#o#6#6#6bQ#oaD.2#6bQ#6.2.xaDaDaD#6aD#6#6aD#6#oaD#o#6#6b3b3aDaDb3#o#oaDaDaDb3#6#obV#o#obV#6#oaD#6#o#6.2#o##aDaDaD#6aDaDaj#YaD#6aD#6aD.b#5aDaD#5#YaD#YaD#6#6#YaDaDaD#6b1#Y#6aDaD#6.baD#oaD#5aD#6#YaD#6#Yb1#6#YaD.B#6.BaDaD",
".2bQ#6#6aDaD#6aDaD#6aDaDaD##aD.2.2aD###EaD#EaD##aE.6#8#8#sa8a8a7#DbZ.t.TaZ.H.g#D.t#v#DaNaqaq.O.R#6#6aD#Y####aD#E##.R.Ob5.Xbt#v#D#s.X#RaQ#v#8.T#sae.H.XaZa7bF.z.t.tbF#vaA.z.t#v.T.taG#D.T.TaE#w#w#w#e#P.zaX#s.g.XaQbtaQ.C#y.x.x.xbH.2aD##aD.x#6#6aD.xbQaD#6.xajaD.x.x#6.E#6aDaj#5ajaj#6#6#6.Baj#6aK#6aDbQ.2aDbQaDaD.2aDaD#6aD.2.2aD#6bQbQ#6#6.2#6aD#6.2#6#6#6#6bQaDaD#6#6#6#6aD#6.2#6#6bQ.2bE#6aD#6#6.xaDaD#6aDaD#6#6#6aDaDaD#6aDaD#6aDaD#6#6#6#6aD#6aD#6#6aD#6aDaD.2aD###o#oaD#6#6b1#YaDaDaD.2.2.2aDaD.2aD.2#6#6aD.2aD#6#6aDaDaDaD#o.B.BajajaD#EaDaDaDaD#6#o#o#o#o.2#6aD#6aD#ob3#6aD.B#5#5#E.OaN#s.T#DaHaHaear.9#dbZ.p#B#BaHbx.l.l.z#A.uaeaOaO.9aF#8aq.R#E#E.R#E.R.X#sbt#zaS#z.6.6aQ.8b5aq.g.T#v.6#8#8#8#8aF#S#v#D#D.T#Dbt.T.T#s#sbcbtb8aQb8bc.6.6#1#8#8#s#w.9.8#g#D#g#g#D#g.9.R##.RaDaDb1#Y#YbV#Y#o#o#6#oaDaDaD#oaD##aDaDaD#6#o#YaDaDaD#6#oaD#oaDaD#o#oaD#6aD#oaD#o#6#oaDaDaD#oaDaDaDaDaDbQ#oaD#oaDaD.2aD#o#6aDaD#oaD#6#6#o#6aD#6#6#6#6#6aD.2#6#o#6#6#o#6#6#6bQ#6#6bQ#o#6.5#6#6.2#oaDbQ#6#6bQ#6b3bQbQbQbQbE#6.2#6.xbQbH#6.x.2#6aD#6#6bQbQ#6aDbE.2#6bQ#oaDbQ.2#6bQ.2#6#6#6#6#6#6#6.2#6aD#6#6aD.2aDaD#6aD#5aD#6aDaD#6#5.baDaDb1#6aDaD#o.baDaDb1aD#oaDaDaDaDaD#oaDb1#5#oaDaD#o.b#Y#6.b#5#6aD#5aD#YaD#6aD.baD",
"aD#6#6#####oaDb1aD######b1b1##aD##.R###E.R##bS#z#S#8aE.9.X.TbYaH#CaG.hbYbYaG.ta7.9ae#D#8.TaNbT#y###6aDaD######b4bc.6#8.M#gbtbt#8#s.X#4.g.zbFaX.taA.z.t.Pau.t.t.zbOaXbFaX.z.z#D#D.z#D#D#vaL#a#S.#bt#DaX.z#P.Xb5#w.Mab#saEaQ#s.C#O#5.x.E.O.O.x#5#y.x.x.x.E.x.x.x.x#5.x.xaD#E.x#5#5.x#5aj.xaDaj.xajaD.x.2.E.2#6#5#6bQ.xaD#6.2#6.2aDaD#6.2#6aK#6aD#6aD#6bH#6#6.x#6bQ.2#6#6bH#6#6.x#6#6#6.xbE#6.2bQ.2aj#6#6#6#6#6.2#6#6.2aD#6b1aD.2#6#6aDaD#6bH#6#6ajaDaD#6.xaD#6aDaD#6.2aDaD#6aDaDbA#oaD#6aD##.2.2#E#EaD#E.2.2.x.2aD#E.2.x.x.x.x.2.x#6.xaj.xaD#y.2#E.2#E##.2.2aD#obQ#6###6#6#6#6#oaD#6ajbQ#E#y#5aNbtbtaG#h#ja7.9ar#3.zau#CaAau.zaZ.MaF#H#a#Pb5b.b5#gb0#sbTaq#waQ.6b8aNae#s#8#s#w.Raqb4bt#8.6#D#8bF#8aXab.#.##saN#w.9#E#Eb.#Eb.apb..xapbHbQ.E.x#5.8#xb8bcbcbt#8#haG#Da7.Xaq.Zbt.Tbt#ga8##aDb1b1bV#obVbV#6#6bQaD#YaDaD#6#6aD#oaD#o#6bQ#oaD#o#6#6#6aDaD#6#6aDaD#6#oaD#6aD#o.2aD#o#6aDaD#6aD#o#6#o#6.2aDaD#6bQ#o#6#6aDaDbQ#6#obQ#oaD.5#6#6bQ#6#6bQ#o#6bQ#6#6bA#6#6bQ#6#6#6#o#6#6#6bQ#6#6#6aD#6b3bQbQbA#6.2#6bQ.5bE.2bQ#6#6.E#6#6bQaD#6bQ#oajaK#6aD.x#6aD.x.x.x.2#E.x.x.xaD#E#6##.R.2aD##aDaD##aD#E##.2aDaD.2#5aD#o##aD#6aDaDaDb1aD#6aD##aDaDaDaDb1b1aD#o###Y#oaDb1#Y##b1#YaDb1aD#Y#5#YaDaD.bb1aD#YaD#Y.baDaD.baD##",
"#6.2aDaD##aDaD##b1###oaD##b1aDaD###E.RaNb8aQaE#S#Saqb5#d.t#I#kaGa6aR.nb9#F.P#kaHae.9.9#g#2.T#EbT.R#5#wb8.#.#aEaEaQ#DbtaEa8aeaQ#D#8aXaFb0#aaAbFbt.z#P#P#P.zbO.t.tbO.zbF.z#s#dbvaOb.b.b5bT.XaQaQabbcab#s#saF#SbXbtaX#s.XaNabaQ.Mbcay.C#y#y#y#O#yaqbSb5.Oaq.Ob5.C#4aq#w.Caq.C.C.C.C.O.Ob5.x.x#y.x#y.xaj#6bQajaD.2.x#6.x#6#E.x#6.x#6#5.xbE.2#6#6aj#6aDaD.x#6aK.x#6#6aj#6.xbQ.xbQ#6.x#6.xbQ.2bHaK#6#6bH#6.xbHaj#6.x#6.xaKaDaD#6#6#6#6.x.2bQ.x#6.xbQaD#6bH#6#6.xaDaD#6aDaD.2aDaD.2#oaDaD#oaD.2.2#E#E#E.R.R.8aN.M#gaQ#s#saQ#gaEaE.M#gaE.k.kay.kaN.g#waq.R#E#O#EaD.2aD#oaD#6aD#6#o#6aD#6aDaDaD#5.ObT#8#8.9#D.Pae.9be.zbYaJaGa7a4a7aGauaAaAbF.XbT.Ra8#g#C.YaL#g#w#wbc#8#1aEaq.Raeb8.6#1#8.6.6bcbcbc.X#y#O#Ob.bTae#D.T.T#D.TbZ#D#D.T.T.T#s#wbHap.EaKbH.E.EbQ.Eapapa8#g.TaF#H#h#DaEbTa8#s.T.T#g.8.RaD#6#6bV#oaD#6#o#6#6#6#6bQ#6#6#6b1aD.2#oaD#6#oaDbQ#oaD#6#6#6#6#ob1aDaD#oaD#oaD#6#6aDb1#oaD#oaDaDaDbQ#oaD#6#o#o.2#6aD#6#o#o#6aD#oaD#6#o#oaD#oaD#6#6#6#6#6aD#6aDaD#6#6#o#6#oaD#6#6#o#6#6#6b3#6aD.2#6#6#6#o#6#6#6#6.2aD#6aD#6#6aD#6#6#5aD#6#E#5.O.xajaD#E#5#yaD.x#y#5#E.O.R#E##.R##.R##.R.R.R.R###E.2.R.2.RaDaDaDaDaD##aDaDaDaDaD.b#5#YaD#Y.bb1aDaDaDaD#Y#6aD#YaD#Y##aD#Yb1aD#YaDaDb1aD.baD#Y.baD#Y##aD.b.b.baDaDaDaD",
".2.2aD#6aD###6###o.2#EaDaD##aD.2#E.Xbtbtbtb8#wbt#S.X.9.9a6aH#r#j#K#j#3aO.Hba.P.j#j.Hbpa8aL#a#8#8#s.X.X#sbXbc.X#4.X#s#8#DaFb0.i#v.Tbt.#bcaEaq#Eb.aq#s.z.zau.P.P.tbFaAaGaA#CaA.t.T.g.x#O.E.E#O#Q.E#Q.E.E.E.8#z#saX.i#aaAaA#e.l.g.z.zbtbXbc.g#4b5bM.C#4.la8.C#4#4#w#4#Ra8#4by#w#4#wb5.laE#Pay.O#y#ybH.x#6.xaD#EbQ.x#6.xaDaD#6.x.2.x#6bQbQbH#6.x#6.x.x.x#6.x#6aD.xbHaj#6bQ#6#6.Eaj#6bH#6#6.EaK.EbH#6aj.x.E#6#6bQ#6#6.EbQ#6.x.xaDbHaj#6bH#6bEbQ.x#6.x#6.x#6.xaDaDaD#5aD.2#EaD#6aDaDbEaDaD.2###E.2.X.T#g.X.g.g#Pbt.zaX.z#s.M#g#g#s#s#gayayay.M#saEa8.9.X#s#s#w.R#E##aD##.2aDaDaD#o#o#6aj###5.Rb5#waF#Db9aLbZbTbTa1#I#IaG#d#3aG.pbIbYa6.9bTb5.R.9#d#s#D.t.6.M#w#E.O#waQ#8#D.6#8#8b8b8#1.4#E#O.2ap.Eapbp.X#D.tbYbY.t.taG.t#D#D#D.taF.t#haFbt#zbS.E.EaK.E.E.5bQ.2.5.2ap#E.Xbcbk#H.T#g#d.R#g#saQaQ.O.xaD#5#6aDaDaD#o###oaD#YaDaD#6#6#o#6aDaDaD#o#6aDaD#o#Y###o#o##aD#oaDaDaD#o#6aDaD#oaDaDaDaD#6aD#o#6b1aD#6aDaD.2#oaD#6#oaD#6aDaD#6#oaD###oaD###obQ#6aD#6#o#6aD#Y#6aDaD.2aD#o#6#6aD#6aD#o.2#6aDb3#6#6#6aD#6.x#6#6.2#6#5#6bH.xaD#6.x.2#6#EaD#yaq.kaQ.M#waqaqb5.RaqbT.R#4.9.R.9#d.R.9#d.RbTaq.RaNbt#g#4.x.2#EaDaD.2aDaDaDaD#6.xaD##aDaD#5#6aDb1aD#Y#6#o###o#6aDaDaDaD#6#6.baD#5aD#6aD#YaDaDaD#Y#5aD#YaDaD.baD#6aD#5aD",
".2.2aDaDaD#6aDaDaD###6.2aDaD.2aDaN#v#8.X.Rb5aq#waA#S.gbM#da1#raMahaJ#q#dba.c#k#B.Pa8bT.H.T#v#D#v#D.gaZb9.z.t.taFaLaL#vbtbt#saE.R.x#Oapap#E#O#4#saLbG#v.z.z#eby.H#d.H.9aZb9#DaG#C#H.z#w.x.E#Q#Q#Q#Q#Q#maC.E.E.E.x.8aEaXb0#H.tbr.H#4aE.z#P.X#4.H.9.H.H.9.H.H#d.H.H#d#d#da8a8.HaZaZbT.HaE#sbF#P.g.Cb5.x.x.2.x#6.x#6.x.2.x.x.x.xbHaD#5bQ.x#6bQ#6aj.x#6#6aK#6aKbH#6.x.2.x.xbH#6.x.x#6#6aj.xbH.2aKbQbHbQ#6#6bHaj#6.xaj.xbQaj#6.x#6.x#6aD.x#6#6#6.xbE.x#6#6aj#6ajaD.x#6.x.xbHaj.x#6.BbEaDaD#5.O#w#gaQ.T#g#d#d.gbrbxa7.z.za1a1a7bx.zbZ.zbx#P#P.z.za1a7#g.Za7#s#saE.8.R#EaDaDaD#6#6b3#6aD#6#5#y#E.X#D#D#gb9bGbFbT.H.z#NaT.TaraeaJ.j#Ia1#0arbpb5.RaObTbT.9#g#s.Tbt#D.#bcbcbcbcbcb4bS.2.2bQapbQap.E.E.E#4#s#HaWbYb2be.9bebZ#D#F#D.Ta7.Z.X.g.T#ha9aLaN#y.E.EaKaKaK.5.5.5.5.5.2.E#wbc#S#2aFae.R.9#saF#8.8b5###5##b1aDaDaDaDb1#6#ob1#o##aD#6#o##aDb1###oaDaDaDb1###6aD#o.2#o#oaDaD#o###oaDaD#o#oaDaD#6aD#6#oaD#oaD#obQ#6#6#oaD#6#6#6#6#6aD#6#6#6#6aD#6bA#6#6bQ#6#6#6#6#6#6#o#6#o###6bQ#6#6#6#6#6#6#6#6.2bAbQ#6bQ#6bQ.E.2#6bQ.2bQaKaD.xaKbQbQ.2aqb4.gaE#saE.Xa8#w.g.gbs.Xa8bsbsbsbsaeae.Z.Z#g#s#ga8aebtaQ.MaE#w#E.2aD#6.x##aD#6aD#6#6aDaD#6aDaDaD##aD#oaDaDaDaDb1aD#6aD#Y#6b1aD#6#Y#Y#6aD.baD#oaDaD.B#YaD#6#Y.baDajaD#oaD",
"aDaDaD##b1####.b########aDaDaD###8#h.X.Rb5aqb5.MaL#v#ebMb9.hbI#k.hb2.c.h.WbI#kaub9#d.9#4#w.XaQ#v#v#D.P#2bY.tbFbt.z#w#yb.#O.2ap.xap#Eapap.8#s.ib0#v#g.Hb5ae.z.M.g#dbTa8.T#D.gar.gaG#2aLay#y#O.EaKbwaCaCbf#Q#Q.E#Q.Eapb.a8.T#H#k#j.ZbTaObT#e.TbF.taG.t.t#v.t.taG#v.taG.t.taFaG#vaF.tbF.z.g.g#s.t#P.8.OaD.x.x#6.2#5aj#6aDaj#6aj.x#6aD#6.2aj.xaDajajaDaj.xajbH#6#6#6aj.B#6aDaj#6#6#6ajaj#6#6#6bH#6#6.x#6#6bH#6ajbQ#6bE.xaDaDbHbQ.x#6.xaK.x.xaD#6bQ#6#6bHaDaj.xaD#6bH#6.xbH#6#6aK#6#oajaj#E.Ob8#va8.R#d.saG.P.P.V.t.V.taG.P.P.P.PbG.P.P.P.ubY.P#H#I#k#j.Xbpbs#8#s##.R.2.2#6aD#o.2#6.x#5###E#w#vaF#e.9bT#vaAb5bTb9#C#NbY#3#d.ZbZ#jaG#F.t.zbc.TaX#Dbt.T.T.T#sbcbcabaS#EapbH.2.5ap.5bQ.E.5.5.5.EapaqbXan.u#Daea8b9a7.Z#D#D#8#D.T#sab#saN.9bsaGa9aHbtbS.E.EaKb3#J#J#Jag#JaK.E.EbH#w#va9b0#ga8bTaEaL#v#w.R####aDb1aDaD#YaD#6aD#o#6b1b1bQaD#Y#oaD#Y#6b1aD#6aD#obQaD#obQaDaD#6aDaD#o#6#6aD#6#6#6.2#6#6.2#o#o.2#6aD.5#6aD#6#6#6#6#6#6#6#6#6aDb3#6#6.2#6#6.2#6#6bQaD#o.2aDaD#6##aD.2#o#obQ#o#6.5aD#obQ#6#6bA#6#6bQ#6.x#6aDbQ#6.x.2.xaD.x.x.x##aQ#8b9bT.X.T#DaFaG#h#haFaGaFaFaFaGaF#j.PbY.u#HaH#HaAbF#e.H#ebFaXaS#EaDaDaD.baD#5aDaDb1bSaDaD##aDaD#YaD##b1aDaDaDaD#YaD#6b1aD#Y.b.b##aDaDaDaD.baD.B##.baD.b.baD.b.baD##aDaD",
"aDaDaDb1b1b1##.bb1aDaDaDaDbSaDaDb8aLae#E.RbT#4#v#S#4bMaebPaT#r.s.n#F.Nb#bU#Ka1.sa6.t.t#DaX.ibk.D.##sbc#s.X#y.2#ObH.E.EbQbH.EbHbQ.5apb..X#h#2#SaE.R#w.z#s#saX.MbMb5b5a8.MaFaFaebT#d.MaL#a.#bJ#Q#Q#Qbwbw#m#mbfbA#Q.5.5.Eap#O.X#h#AaHbOb7.n.P.Y#2#vbF.za7#saQaQ#zaQ.MaQ#g.M.MaQaQ#sbFaHaT#FaO.H.T.PaE.xaDaDaj#6ajaD.B#6#Y.B.B.B.B#6#5#6bE#6#6#6.x#6#5#6.2#oaD#6.xaK.x#6.xaD.x#6bH#6bH#o#6bHbEbQ.2aj#6bEbQb3#6b3bEbQbQ.2aD.x#6bQaKbEbQbQ.2#6bH#6bHbQ.Baj#6#6aj#6bH.x.2bH.2bHaKaj#6bH#5.B.x.O#8.T.RbpaeaHaWbPa7.n.H#d.H#4aq.C#4#4#waS.C#wb4aN.X.MaG#I#M.Tbp.R#D#h.X#E.2#6.2#o#6bQ#o#6aD#y#Ebc.iaNbTb5bv#w#v.##w.H.X#DaJ#C#7bZbsb7a6br.T.T.6ab#s#s#saE#4#ybH.E.E.E.E#Q.E.E#QbH.5aCaCbfbfbw.E#Q#Oa7#A#2.Mb5b5#g#h#gb5b5#y.Rb5#y#E#wbcbX#g.9.9#g#Ha9#s.2.E.E.Ebw#J#J.v.vbwaK.E.EbQaDaNb0aH.T.9bTaeaF#vaq.x####.2#6aD#6#oaDbA#6#6bQ#6bQbQbVbVbVb3#6bQ#6aDaD.2bA#6#6#6aD.2aD.2aDaDb1bE#6#6#6#6.2.2.2#6bV#o#6#6aD.2#6aD#6#6aD#6#6#6#o#6#6aD#ob3aD#Y.2aDaD.2#EaD#E##aDaDaD.2aD#Y#o#o#o#o#oaD#o#6aD#6#6#6#6aD#o#6#6bEaDaDaj#EaD#E#5aD.xaDaD.k#S.Mb5#daG#N#IbY.T.z.T#P#s#saQaQaQ#saQaQ.M#s.MaQ#PbP.AaJ.s.Hby.tbt.O#5aDaD#5aDaD#Y.BaD.baDaD#5aDaD#YaDaDbS##aD#YaD#Yb1aD##aD#Y#Y#Y.b##aDaDaDaD##aD.b.b#5.b.O#Y.b##aD.b.b#5",
"#o#6#Y###Y##b1b1##aD######.baDaD.X#S#hae.R.RaN#a#8b5bT.t#NaT#FaRa4.J.Sbg#r#j.J#C.W#KaG#Dbc#1#z.ObHaK.EaK.EbH.EaK.Ebwbfb3bAbAbQbQapb..XaLa9#8#db5a8aF.i.z.C#yb5#Ob5#E.2#E.8#8.i#s.9b5b9.u#A#vbJ#Q#Qbw.vbw.vbwbwbwaC#Q.5bQapapaq.TaHbIa1b7a7.taLaF.za1a8#O#Q.E#Q.E#Q.E.E.E.E.E.E.EbT#j#M#7.H.9ae#H#s.x#5aD#6.xaj#6.BbE.B.B.Bajajaj.baj.x#6.xaD.2aD.2#6aD#6#6bE#o#6#6.x.x#6#6bQ#6bEb3aj#oaKbQ.2bQ.2bQ#6b3aKb3#6b3#6bQ.2aD.2.x.2bQ#6#6.E.2#6#6#6aKbAbE#6bE#6.xaDaD.x.2bQ.2bHaKaK.f.B.BajbH#y.#aF#w.la8#PbG.uaAbZ.za7.l#Q#Q#m#Q#QaC.vbfaC#Q#QaC.EbeaJaVbZbTbT#s#H.Z#E#E#6#6#6#6#6aD.x.xaD#y#1bXb5#y#y#yb5#w#8#8aebT.9.ZbZ#j#r#KaGbZ.T.T.Tab#1.oaQ.Xb..E#QaCbwbwbf.EaCbfaC.EaCaCbfaCbfbfbwaC.EbT#j#MaAa8b5a8aL#8aq.R#y#E#E#E#E#5#y#5#1.iaN.R.R#s#2#h#4.E.E.E#Q#QbfbfbfbfbfbfaC.E.5apaN#H#2.ZaObMae#v#gb.#E##.2.2#6bAbE#6aKbE.xaKbQ.EbQ#6bVbA#6b3.2.2.2aDbQbQbQbQbQ.2.2.2.x.x.xaj.B.Baj.x#E.x.2.2bQ.2#o#6.2.2.2.2.2.2#6.2#6#6b3aD#6b3#o#obE#YaD.2#E.R.2.R#EaD###EaD.RaDaD#YaD#o#o#Y#oaDaDaD.2aDaDb3#o#obEbE#6.f#6aj.x#6#y#y.R#y.O#z#z#1#S.Mb5.9#saJ#kaGbra7by#E.EaCaCbfaC#Q#Q#Q#Q.E.E#QbH#P.pb##p#dar#D.6.RaD#E.xaD#Y#Y#obE.Bbj##aD##aD.B#YaDaD.R####aDbV#YaD#E##aD#o.B#Y##aDaDaD##b1######aD#5.b.b#5.b.b#Y###Y.b",
"#6#6aD#YaD#YaDb1aDaDbj##aD##aDaDaE#haF.X.R.R.8.i#Saqb5ae#HaTaHb2bs#e#F#p#F#F.t.Ta6#dbpb..x.EaK.E.EaKb3bAaK.EaKbAbA#Jbw#J#JbAaKbQap#daF#k#D#d.R#d.t#2#S.T#P.gb5#O#y#Eap.x#Eaqbt#h#gar.9.z#2#AaQ#O.Ebwbw#m.v.vbfbf#JbfbA.E.5aC.5#E.T.A.p.c.H.laEbX.u#N.h#4.E#Q#m#Qbf#QaC.5#QaCbw.Eb5au.AaG#darae#HbcaD#6bE.x#6#6bH#6bE.BajajbHbH.x#5#E.x.x.x#EaD.2aD.2.2#6#6b3aD#6#6#6.x.x#6bHbEbQaK#6#6#6.2bQ.2.2.2#6.2bQb3bQbQ.2bQ.2.x.x.2bH.x#6.2bQ#6bQaK#6bQaK#6bQ#6#6ajaj.x#6.xbQ#6aDbQ#6#6bH#6#5bH.x#RaQ.za7aZaO.g.M#PaG#r#Iay.E#Q#m#Q#m#m.v.vaCbwbw#m#Q#4#KaVbZaO#ya7#C#s#y.2#6bQaDaD#6#5.x.x#y#E.obX.C#yb.#O.R.O.OaE#z.Mbt.Z.9.Xa6.TbZ#D.T.T.T.#ab#SbiaF.9ap.Ebw.v#JbfbfaCbfbwaC.Ebfbfbfbf.v.v#m.E#3bU#M.z.lbT#sb0.Mb5#w#g#1.g#y#5b5#5#y#w.DaX.lar#daGa9#gap.5.E#QbfbfaCbfbf.vbfbAaC.Eap#E.T.Y#D.9aOb5bF#v.9aD#E.2.2aDbQ#6#6.EajajbH.x.x.x.x#6.2.2.2#E.2#E.2bQb3.2bE#6aDbQ.E.2.xaj#5.x#5aj.x.x.xbH.2.2bQ.2.2#E#O.2.x#E.2.2bQbQaDbQ.2#6.x#6#6.f#6aj.xaD.R#E####aD##aDaDaD####aD#6#6#6#oaD#o.2aD#E.2#EbQbE#obE.2#6aKajaj.x#y#E#E#y.X.MaQb8aS#z.z#sa8bT.ZbZatbY.p.P.g.E#maCbfbfaC#m#m#Q#Q#Q#Q#OaybIbu#p#dar.T#vbS#EaDaDaDajbE#o#obE#6#5aD#5#E#6#Y#5#E.R.R###o#6#6aD##bT.2bVbV.B#oaDaDaD##.baDaDaD#5aD#########5aj#5aD.b",
"aK#6#o#o#o#oaDaDaDaDaDaD#oaD.2bSbKaF#w.R#E.R#EaN.D#v#w.R#e#DaH.paG#DaG#7aG.t.z#D#Dbs#O#O.E#QaK.EbAbw#J.EbAbA.EbwaKbwbfbfbwbA.E.5###DaW#ha8.9.9#saLaX.MaQaXbc#saEb5#E.R#y#O#ya8#D#h.gaO#V.P#BaAbJ#Q#Q#m#m#m#m.v.vbfbwbfbf#Q#Q.E.Eaq.haT.h#db5#yaqau#NaHay#O#m#mbf#Q#maC#QaCbfbw.Eb5aG.A.h#db5.Z#Hbc#6.2bEajaj.x.xbHbH.x.x#y#Eb.b.bv.x#E#Eap.2.x.2#E.2.2#6.xaK.B#6bH.xbQbQbEbEb3aKbEbEaKbQbQbQaD.2.E#E.x.2#E.x.2#Oap#Ob.b.#O#O.x.x.x.2bHaK.2.xbQ.x#6bHaj#6bH#6#6bH#6#6#6#5#6bHaj#6.x#y#y#O#Eb..X.T#e#e#Rb5bMa4#K.A#P#Q#Q#maCaC#m.vbf#m#maC#m#Q#d#K#.#FaObv#g#Ha7b..xaD#6#6#6.x.x#E#E.x#yaS#vaEb5#E.x.x#E.xaDbSaN#1aE#wa7bt#saQaN.Caqb5#y.x.k.uaH#g#O.Ebw.vbwaC.5bfaCaCbwaCaCbfbfaC.v.v#Q.E.Tb##k#ebvb5#D#8a8bTbT#g.t.#aEb5#E#Eb5#y#P.t#daO.9#D#I#sb..E.EaC#Qbfbfbf.v.vagbwaC.5#Q.EaE#2#H.gb5aO.TaLaN.RaD.2.2aD#E.xaD.x.x.x#y.O.x#E#E#E.R.Rb..R.R.2.2.x.x#6#6#6#6#6bQaD#5#5b5#yaO#y#y#y.x.x#E.x#O#Eb.#E.R#O#E.R#E#y#E.x#y.x#E#5#y.x.x.x#5#5#yaD#E#E.2aDaDaDaD#6.xaD.2#EaD#EaD.2#6.2#E#E#E#E.x.2.2aD.2.x.x.E#5.xap#E#E#ObsaF.M#y#y#O#y#R#gae.Z.Z#dara1bI#A#P#O#QaC#m#maC#m#maC#Q#Q#Q#Q.M.p.7#p#db5.T#8##.x.xbH#6bHaK#6.x.2#E.xap#E#E.x#5.2#Ob..R#EaD#6.2.2.R.R.x.x.B.B#6aDaj#oaDaj.BaD#6aDaDaDaD#5#5#6aj.BaD##",
"bEbQbQaDaD#o#6aD#o.2aDaDaDaD.2.8.D#8.Rb..R#E.Raqb4#8#8.Taearae#D.taF#D#DaG#hbYaW.YbZb.apaKbwbwbwbwbwbwbAbw.EbwbAbwbwbfbwaC#Q.5.EaEa9#Hae.R.9b9aF.Mb5b5b5b5#w.z#S#saq#E#y.RbTb5.T#k.Tar#0bZbI#2aN#Q#Q.v#m.v.vbw.v.v.vbAbA#Q#Q#Q#Q#O#P.A.Wb7#yb5bMaFaT.p#e.E#Q#Qbwbfbf#maCbfbf.v#Qaqau.A.h.narb9aHaQ.x#5bH#E#5bH#y#y#Ob5b.b.bpbpbp.Rb.#O#Eb.#Eb.#E#O.2#EaD.xbHajbH#6#6bH#6#6aK.2bQbQaD#6.E.E.x.x.x.2.xap#E#E#O#yb.b..Rbpbvb.b.#O#y#E.x#E.x.xaD.xbH.x#E#6bHbEaD#5#oajbHbQ#5ajbHaj.x.x#y.xaOaOb.b.b5#daG#Pb5bTba.h.A#s.E#Q#Q#QaC#m#maC#m#maC#Q#Qa8#K.A#Fbvbv#e.u.zb5.x#5.x.x#5#5.x.x#E#5#E#yaNbcbc#w.x.R#5.x.x.xbH.x#yb5aN#s.o#zaSbJaya7bT.x#yaXaW.z#O.E#Q.vbwaCaCaCaCbfaC#QbfbfbfaC.vbwbwapbr#.#ja8b5b5.zaXb5b5b5#E#E.XbXaeb5bMb.b5bFaGb7#0ar#F#B.Tap.5#QaCbfbfbfbf.vbh.v.v#m.E#Q.EaE#2.uaeb5bTa7aFaN###E#EaD#E.2#E###E.x.Rb5b5#y#y.RbTbp.Rbpbpbp.R.R#E#6aj.x.x.x.x.x#E#E#E.RbpbTaObv#y#y.x#ybvbpbpbp.Rbpb..R.R.R.R.Rb.#y#Eb.#waEb5b5#4bM#4.gaq#E#E#E.2.x#E.xaj#y.x.x#y#E#E.2bH.2#E#O.Rbpb.b.b.b.#E#E#E#E#E#O.x#yb.#Obpa7#hae#E#Obv#O#Ob..H.z#j.gbp#F.A#A#P#O#Q#Q#m#maC#maCaCaC.5#Q#Q.gaz#.#p#db.#s#8bSbHap.x.x.x.x.x#O#E#y#O#Ebpb.#E.R#Eb.bp#O.R#E.2#E.Rb.b.b.#O.xaj#6#6#6bE#6.BaD.BbE.2bHaD#5.x##aD.xaD#5.B",
"bQb3#o#6aD#oaDaDaDaD#6#6aD####.8.D#8.R#Eb..R##.R.R.OaE#s#g#s#D#D.zaE.X#d.9.9.XaL.YaG.R.E.Eb3#Jbwbw#J#JaKbwbAbwbAbfbfbwbfbf.E.5###vaW.tbTbpa8aF.tbT#yb.#y#yb5bT.MaFaEb5bTb5.Rb5braHa6arar.TbI#H#R.E#QbwaC.vbwbfagbfbwbwbw#Q#Q#Q#Qb..z.AbN#db..l.H.t#MbI#P#O#QbwaC.vbwbfaCbfbw#J.E.OaF.AbNaZ.Hb9aH.T#E#y#E.xb5#4aE#s#s#s.T.Tbr#g#ga7.T.T.T.T#saEaq#E#EbH#y.xbHbE.xbHbHbHbHbH.x#6bH#6#6.x.xbH.E#y#Eb.b5bTa8.M#s.T#s#P#D.t.zaX.z.zbt#P#xbSaD#E#Eap.2#y#E.x.x.x.B.BbE#6.xaK#5#5#E#y#y#w.M.M.T.z#ga7#g.MaG#sbvaOaeaJaT.T.E#Q#QaCaCaC#maC#m#m.v#Q#Qa8aJb##FaO#y.M.Wa7#y#E.x.2.x.2.2.x.x.E#E.xbQ#EaSaQ#sbcaS#E#E.x.xaj.x#E.x#O.x.x.xajaj#s.P.g#y#y#PaWaGb5.E#Q.v#mbfaCaCaCbf#QaCaCaCbfbfbw.v#m.xbr#M.Var#ybM#v.zaOaObvb5#ybv#PaA.g.Hb5.H.h#F#0aRb7#j#B.T.E.E#QbwbfbfaCbf.v.v.v.v#Q#Q#Q#ObtaW#v#dbTbT.TaFaq.RaD#E#E#y.R.R#y.R#4aE#sbtbt.T.t#Dbr.T.T.T.T#D#8aQ#z#RbSb5b5b.b5#w#g.T#F.T#D.T#saXaX#Pab.z.zbF#D.T.T#s.T#D#P.T.T#P.T.Mb5.X#v.t.zaGaGaG#j.t#D.T#sbt.Tabbt#s#P.M#4b5.Rap.x.x.8#g.T.Ta7.T.Z.9.9.9bpbT.R#y#4#w.g#s#s.T.P#k.t#dbvb.b5.l#Ob.br#hbe.9#q.p.p.t#O#QaCaCaC#maC#maC.5#Q#Q#Q.gaHb##Kb7b.#s#v.C#y#y.x#y#E#Ob..R#EbT.Xae#s.T#s.T#g#g.TaQ.T#saQbc#sa7bsarb5#y.x#y#5bHaj#Yaj.B#YaDaDaD.x#E#####5.baD.BaD",
"#6#6aD#o#o#oaDb1#o##b1aD##b1aD##aQaFaE.R#E.R###E#E#E###EbTaE#D#D#s#g#s.t.ZbTaO.T.Y#H.XbHaK#J#Jb3bV#J#Jb3bwaKb3aKbw#mbfbA#Q.E.2aN#H#H.ZbTaO#sb0b9b5bp#y.Rb.#ybT.H#s.t.MbT#yb5#eaLaG#dbpbaaGaW#D#y.E#QaC.vaC.vbfbwbfbwaC#Q#Q#Q#Q.E.g.u#N#Fb5#Ob5.H.t#u.A#P#O#Q#Qbf#J.vbfbfag#J.vaK.laG#u.Wa4bM#e#C#D.9#g.zb9.X#4#gaXbt#DaX.T.T.Ta7.T.T.T#D#D#s#g.X.XaQaQ#z.C#y#y#ybH.xbH.x.x.x.x.x.x.x.x#y#5.C#s#saE#R.H.X#s#s#D#D.T#DbF.zbFaX.z#P.oaS#4#Rabbt#wb5#E#O#E#E.x.x#6bHaj.xbH#y.CaQaQ.g.X.M#s#s#s#s#s#g.Zb9#wb5b5a6#I.A#s#Q#QaCaCaCaC#m#maC#m#m#m#Qa8#X.AbZaObv.M#C#s#y.x.xbH.2#5.2.x.x.2.2.xap#E#E.2aNaQaE.8#zb8.4#y.O#y.x#Eb.#O.x#y.x#g.ua7.xbv#P#k#Ca8.E#Q#mbwaCaCbfaCbfaCaCaCbf.vaCbf.v#m#O#F.S#Fb5bvby.P.zbT#daea7#P.TaAa9aLbF.t#v#Ca6araRb2aH#2aN.E#QaCbwbf.vaCaCbfaC#m#Q#Q#Q.E#RbG.uaeb5bTbeaG#sb5#E.O#y#Ea8#sbt#s.Za8ae#s.T#s#8#D.T.T#F.T#D#D.Tbc#PaQ.X#w#ebrbZbe.g.T#DbZ.TbZ#D.T#DaX.zbF.z.z.zbF#D.T.T#D#D.T.T#D.z.Ta7#d.H.Ma7bZ#7#F#F#F#D.T#D.T#D#D#D.z.t.t#gaZaeaQ#s.M.C.XaQ#s#D#Dbr.Zb7b7#d.9.9.9#4#w.X#g#s#s#D#D#Da7aZ.M.M#P#R#yb5.T.P#eaOa7#kaV.z#y.EaC#maCaCaC#maC.5aC#Q.E#R.W#..JaZb5.M.D#w#y#E#E#ybT.Xbt#P.X#4.X#g.T.T#Dbt.TbZ.T.T.T.##sab#D.M.gb7ae.T.M.C#y#y#y#5#5aj#5#Y#5#5aDaD######.b.b#5b1",
"#6b3#YaDaDaDaDaDaDaD##b1aD##aDaD##aNbcbcaQ.8#EaD#E.2.R#Eb..R#E.R#EaDaeb0.t.9#E#ga9#N#s.x.E#J#J#Jb3#Jb3#Jb3b3aKb3b3bwbw#QaC.5#Eb8a9aF.HaObp.z.t.9b5aOarbT#w.zaX.zaF#2#2bF.z.T.T.tae.R.9bZ#2.P#w.E.EbwaC.vaCbf.vbwaCaCaC.E.E.E#yaybG#NaAbsaraOb5.HaG#M.Abx.E#Qbwbfag.vbfbfbfbfbw#Qbv.t#uaJa4#0aZ#C#Ka6a6#Fa7ae#4.M.taX#v#8#D#8#8bt.taF#D#D#Dbt.M.X.X.Mab.MaN#P#P.gaq#y.x#y.x#O.x.x#Oaqay#s.MaN#s#P#g#wbT.X.M.TaG.t.zbF.z.zbFbF.z#PaN#4.O#w#sbt#gaea7#g.9#E.x.x.xaj#y#4aQaQay#P#s#wbT#w#g#s.6#DbtbtbtaX#Pbc.T#h#I#I#g#Q#m#m#maC#mbl#m#m#m#m#m#Q.gaJb#a1b5.l.MbYb9#y#E.x.E#6#E.2.x.x.2#EbQ#E.2.2.2#E#E.R#w#gb8.8#E.O#w.Xa7.T#w#y#yb5#e#CbF#y#y#eaJ#kb9.E#QbwaCaCbA.5bf.vaCaCaCbfbfaC.vbw#Q#EaG#MbW.l#yaebG.Paeby#e.Ma7.z.zbF.z.z.t.ta7#darbe#ha9.6#E#Qbwbw.vaCbfaCaC.E#Q#Q.E.E#y.Mb0aL.MbTb.ae#v.t#d#Ob5#g#s.Maea7.T.Tae#4bs#g#8bt.##D.T#D#Dbt#D#DaXaXbc.ga8#db9bZb2b7b7.s#F#D.Tbt#D#D.t.t.t.tbFaXbXbX#8.z#8.t#D.t.t#F.T#e.Har.H.n.T#F#p#F#FaG.t#D.t#v#D.z.t#F#7#F.sbsb9.z#s.M#waq#waN#8aG#D#D#D#DaFaG.t.taF#8#8#v#8aX#D.za7.ga8.s#P#P.gb9bZ#haLb9bT#q#.bIa1#O#Q.5aCaCaC#maCaC.5aC#Q#Q.CbYaV.Jbeb..MaF.g#y#4b9#saeae#sa7.XbsaE.T#D.T.t#D#DaG.t.T.t#v.#bF#v#D#D.Ta7.T#P.g.gaXay.O#y#5ajaj#5ajaD.OaD#5aDaD#5#6aD",
"bE#6aD#o#oaD#Y#oaDaD#6.2##b1.2#6#EbH.8aQ#zb4#1.6#x#####E.R.R#O#E#O.2.RaFaG#d.Ra8#H#B.Tap.Eb3#Jb3bVag.3b3b3b3bAb3bwbfbwbA#Q.Eb..T.Y#D.9bT.H.t#D.ga7.zae.ga7.z#P.t.t.taG.t.z#s.gbTa8a7#8#H#S#w.x.E.EbfaC.v#maCbfaCbw.EbH.E#O.g#v#2avbFa8ar.Z.gbT.H#7.r.Aa7#O#Q#m.v.vagbfbfbfbfbw.E#E#F#u.N.s.H#da6brbebabr#D.taA#a#aaF#DaXbtbc.o.obc.zbtaXaL#a#a.ibX#vbt.g.H#e#P.M.M.M#w#y#E#ObMae#P.M.M#PaEaObyaQbtbtaXaF#a.uaF#D#sbcbt.oabaX.#aA#aaAaX#P.zaebT.X#s#g.Z.M#wb5.O#wbcaQ#P#P.g.H#gaXaXaF#S#8.6b8bc.obc#sbcab.i#AaWaWaQ#QaCaCaCaC#m#m#maC#m#m#m#Qae#r#M#Far#y#P.Pae#O.x#6bE.2bE.2#6.x.x#6.2.2.2.2.2.2.2#E#EaD#E#E.x.R.8.XaQb0.T.9.2#Ebe#j.zbMb5#d.h#Ia7#O#Q#Q.v#QaCbwbfaCaCaCaCbwaCbfaCbwaK.OaGb#bZaObv#4#P.z.g.HaO.Hb9#P.z.z.z.z.za1a1#P.TbYa9aF.C#QaC.v.vbwbwaCaC.5.E.E.E#y.X#v.u.P#e.9aO.gaGaG.X#w#s.Ma7.z#s.Xbs.Z#D.T#DaFb0aL.#btabab#PbtabbtaXaX#v.i#S#v.t#F#7#F#FbN#r.WbF#D.T#D#D#D#DaG#D.#bXbKababbcbtbtaX.z.z.zbFau.t#e.sbP#N#k#j#7.t#D#8#8#8aX#DaX.z#FaG#raVaua6beb9#D.tbt#vaLaFbt.T#s#sbcbt.Tbt#s#sbc.o.o#1bcaX#h#2b0.tbt#e#R#4#e.T.PaL.X.la6aV#.bZ#O#Q#QaCaCaCaC#maCaCaCaC#Q#4bY#faJa4b.#g#H.t.Ta7#gbrbsa8a7.T#D#v.u#a#vbt.T.T#s#s#s#sbtaXaXbFaL#AbiaH.P.t#D#q.s.z#Payay#R#y#y#5#5.x#6aD.x#6#6#6.xaD",
"#o#6b3#6aD#o#6#6#6.2aDaDaDaD#6.2.2#E.O.xaD#x#1.6#z##bS.8#zb4#E.R#E#E.R#D#haebT#d#j.j.t#E.Eb3b3b3b3#J#Jb3bAb3b3bwbAbwbAaC#QbQb.bt.Y#D#dbT.gb0.uaG.t.z#eaZ#ga7.M#D.z#qa7#P.z.t#8#D#vaFbtaQbSbH.EaC#Qbw.vaCbfbf.E#Q.5.x.XaQ#8.u#H.t#e.Hbsa7bY.t.H.H#7.r#ua1.E#Qbw.vbf#Jbf.5bfbf#Q.Eb.#7#M#r#q#0ar.X#F#F#haWaHbXbc#saNaqbv.xap.E#O.E.E#O.Eb..CaEaQ.oab.i.abGaX.zaZ.l.MbF.z#D#s.MaX.z#PaebTa8#P#DaA#2#S.6bcbcaEaNbT#E#O#O.E.E.E.E#y#RaQ#sbc#v#a.u#DbZ.Z.9a8#s.T.TbX.#.z.g.l.g.T#v.uaL#saQb4.O.E#Q#Q.E.E.E.EbH.C#s.TbtaS.EbwbAaCaCaC.vbfaCaCaC#m.Eae#f#M#F.lb5#P.hae#y.x.x#o#6aKaj#6bA#6aD.2aD#6.2.2aD.2#E#EbH.2#E.2#E.Rap.9aG.T.Rbpb.#daGbF.lb5.H#j.Aa7#O#Q#mbw#QaCaCaC.vbw#QbwbfbwaCbw.vaCaq#j#Ma1bvbvbvb5aZbx.zbFbZa1.z.z.z.z.zbZbFaGaL#2#2#v.C#Q#Q#Qbw.v#JbfaC.5bQap#4#sbFaFaF.zaZ.9.n.z.tbZ#P.T#P.z.s#d#db9#DaF#H#hbtbtbcaE#4.x#O#O.E.Eb.#O#Ob.bv#5#RaQab#D#h#kaT.r#uaMaz#ebvb.#Ob.b.b.#E.x#ybEbE.EbHbH#O#Oap#O#y.gbFav#Bau.t.Y#BaHa7.H#ybHbH.xbH.x.xb.bvbv#dbNaM#MaJ#jaH#hbtbc#saNaq#Oap.E.E.E.Eap#Oapap.E#Q.E.E.E.xbS#gaQbt.ibkbF#Pbsara8aE.9#ybr#f#.#F#O#QaCaCaCaC#m#maC.5aCaC#QaqbYb##r.sbp#e.u.hbZbsbsbra7aF#2aLbt#saQ.k.O#O#O#O#O#O#O#O#O#Obv#y.Cayabbt#v#2#N.W.ta1#e#e.z#Pay#y#yajaj#6#6aDaDajaD#5aD",
"bQ#6aD#o#6#o###6#oaD#oaDaD##.2aDaD.x#E.x.x#5aD##b1####.8.D#8aqaq##.R.R#D#k.T.9.9aGaT#C.9.2bwbwbA#Jag#Jagb3bAbAbw#JbfaC#Q.5.Eb.#DaW.T.9aOaeaH.u.Ma8#ebF.t#Hav.P.PaJaHaJ.h.zab.Tbcbc#wap.E.E.E#QbwbwaCaC#maCbwb1#z#1.6bkbiaH.T.Zarb5bva7#IaW#D.H#0#7.r#Ma1#O#Qbwbwbfagbf.5aCbf#Q.Eb.#F#M.NbO.Z.z#haW#Hbt.o.k.x.E.Eap#Oap.Eb5#R.MaQ#PaN#y.E.E.E#O.E.E.OaybtaAa9bPa1ae.H.g.zaF.P#g.9.9b9.taFb0#v.o#zbJaK.E.5.E.5.5apap.x.xbH.E.E.E.E.E.E#O.R.X#s#D#2a9aF.Z.9.8.Mbt.g.9b7#DbY#HaF#saqap.E#Q.E#Q#maC#Q#Q.E.E#Q.E#Oap.xbH#Q#JbwbfaCbf.vbfaCbfbf#Q#Q#gaV#M#Fb5bv#s.P.gb.ajbEaK.BaKaK.BbHbQbE.E.2.2bQ.2.2.2.2.xbH#6bHaK.x#E#E.R#saFa8.Rbp.9#7.tbTbv.H#j#Ma7#O#Q#QaCbwaCbfbwbwaCbwaCbwbAaCbw.v#QbS#hb#brbv#y#4#PbPaLbF.zbxaZaOaOaObvaOb5.l#4.gay.k.O.E#Q#Qbw#Jbw#mbw#6aSb8#8#h#H.tae.9#0bsb2.tbFa7.zaGbFae.9aZa1aGaH#h#s#g#wb.ap.E.x.E.E#O#4#P#P#P#PaN#y.E.E#ObH.E#OaqaE.TaA.paTaTavbO.za8b.apapap.EaK#Q#Qbw#Q#Q.EbH#O.Cbt#HaWav#v.s#e.z.z.t.t#vabbJbw.f.E.E#O#4.z.t.h.p#uaT#C#D#gaq#Oap.2apb.#w#s#s.zaQ#P#P.Ma8#Oap#Q.E.E#Q#Q.E#O#Q.E.C.obX.ubYa6.9b..xbvbrbUb##F#O.EaCaCaCaC#m#maCaC.5aC#Qb5.hb##bb9ar.na6bsbebrbY#k#H#8#s.8ap.x.E.E.E#O.l#g.z.z.z#P#P.zby#O#O#O.E#O#yaE.T#K#I.A.Pa4#dbxbF.zay.l.x#5#5#5#YaD#5#Y#5",
"#o#oaD###oaD#YaD#######oaD##aDaDaD.xaDaD.2aDaD##.2aD#E##.6.D.8###EaD.9.T#kaG.9ar#F.S#kae.2aKbwbAbAb3agb3bAb3bwbfbfbw#m#Q#Q.5.RaFa9a7#ybv#sbY#eb5ae#H.Y#H.tbc.gaea6a7bZ.zaE.Mbc#s#saE.Oap.E.E#Qbw#mbwaC#maCaC#Yb8#1#1.6#a#H.t.t.Tbsb5ae#DaGa7ar#daxa0.Gbx#O#Qbwbf.vbwbAaC.5bA#Q.Eb.bZ#M#uaz#H#N#H#s#waK#Q#Qbw#Q#Q#Qapap#waGaH#2bG#a#a#vbJ#O.E#Q.E#Q.E.E.E.O.MaFaH.Pb9#dbTae.g.laebF#H#HbtaN.xaC.E.E#maC.E.5.5aqaQ.o#1bK#1.o#wb..E.E.E.E#Q.5.E.RaNbt#H.u#s#wb5bpb..gbY#IbY#gaq.E.E#Q#m#maCaC#m#Q#Q#Q#O#y.Ob5#O.E#O.E#Q.vbwaCaC.v.vbfaCbwaCbw#Qb9aV#M#FaO#y#P#jbs#E.xbQbE.B#oaj#6aK#6.2#6#6.x.x#EaD.x.xajbH.f.BaKaj.x.2.R.6.i#g#E.R#daGbF#4.l#0#7.Abr#O#Q#mbw#QaCbf#m.vbf#Q.5bfbfaCbwbw.Eb5#hb#a1.lbyaAaW#HaeaOa8#PbF.z.zaX.z.z#P.g#y#O#O.E.E#Q.E#Qbw#m.v.vbAaD#xbt#8aH#HaG.T.9bpbs.caGau.t.ta7#da8brbYaWbY#s#4ap.E.5.5.E.E.E.E#y.gaA#abP.t.ubI#v#4#O#Q.E#Qbw.EaKbH#yaybFavaMaM#uaJaeb.bH.E.E#QaKaKaK#Q#Q#Q.E.EaNbGbibG.M.Hbv#y.l.l.HbO#abiabbH.E#O#O.g#C.r.r.r.r.p.z#w#E.E.E#Q#Q.E.EaqaF#NaTazax.haz#kaA#4.E.E#QaCaC#Q#Q.E.E#Q.E.E.ObF#k#r.Z#y#y#yb2bLb##F#O#QaCaCaC#m.vaCaC.5aCbf#Q.RaGb##r#qaObTb7a7#j#k#H#DaE.R.5.E.E.E.E.E#Q.C.tavaT#2aA.u#B#ubP.g#O#Q.E.E.Eapapa8.T.W.A.W#qby.g.z#vay.O#5aj#Y#5#6.BaDaD",
"aD#o#6#YaD#o.2#o#o#6aD##aDaDaD.2.2aDajbQ#6aDaD#6aD.2#EbSbt.iaN.2####.2bs#H#j.9ar#7#M#M#sapaKbAbAaKagb3bAb3bwbwbfbw.vaC#Q#Q.5aq#ha9#gbpaOa7bF.HarbxaH.YbPa8b.b5.g.z#D.t.taG#v#v#v#v#vaX#s.o.o.4.E#Q.EaC#Q.E#maCaK.5.5.2aSb8.TaF#2.P#8a7a8a8#d.9.H#7#i#.#q.E#Qbw#J.v#JaC.Ebfbf#Q.E#O#F#M.j.Y#2bX#w.2#QaC.v.vbhbwbw.Eapa8bY#IbYa7ae.M.PbibG.C.E#Q.E.E#Q.E#Q.EapbTaE#h#2aub9bTar#s.ub0.##wbH.E.EaC#Q#Q#m#QaC.E#w#hb0#8#1#1#1.Dbk.M#y.E.E.E.5#Q.E#Q.Eap.8#8#ab0a7#daebYaW#h.8ap.5aC#Q#Q#Q#m#m#m#QaC#Q.O#P#vbXbFbF.z.C#Q#m.v.v#m#mbf.v.vaCbfaCbw.EayaV.SbZaO#y.z.P.gb.#E#6#6aDaDajaDaj.x#5.RaD#y###E#E.x.x.x.xajajbHaj#5.x.R#8anb8#E#Ea8#j.tbTb.#d#j.S.Tap#Q#Q.vbwaC.v.v#maCbfaCbfaCaCbwbw#Q#yaG#.b2b5ayav.YbFaObva8.P#B.uaX.taX.z.PaAaXab#RbH#O#O#Q#Q#Q#QbwbwaKaC.5.5.RaN.TaFaH#v.T#ear.g.zbObyaO#eau.ub0.z#wap.2.5#Q#Q#Q.E#Q.E#yaybG.ubFby.H.ZbP.YaA.O.E.Ebwbwbwbwbw#Q.x.l.gbPaM#uaT.W.gap.E.E.EbwaKaK.fbw#Q#Q.E#yaQ#abGaebMbMbv#y#y.l.z.p#aay#O#O#O#RazaMaI.r.rbL#qbv.E#J#J#J#Jbw.E.Eaqa7#C#M#b#p.0.c.WbI#P.x.E#Q#QbwaCaCaCaK.E.E.E#O.g#r#M.Tb5.O#ybx#fb##Fb.#QaCaCaC#m#m.vaC.5aCbf.E#E.Vbq#f.car#d.VaV#I#h.Xapap.5aC.E.E#Q.E.E.l#vbI.AbP.sbya4bP#u#u.h#4.E.E#Q#Q#Q#Q.Eb.#waF#IaHbx.H#0.M.t.M.O.E.BaD#6ajaDaj",
"b3#6aD#obQ#6#6#6aD###6.2aDaDbQ#6aDaKbQb3.2.2#6.2.2.2#E#Eb4bkaQ.R##.2.2.9#h#h#dar#F#M.j.T.x#QaKbAbAb3bA#JbAbAbf.v#m.vbw#Q.E.5.Xb0a9a7bT.la7#Hbx.H#d#P.h.uaAbZ.tbYbYaGbZ#Paea8#R#w#Rae.M#v#v#S#SabaS#Q#Q.E#Q#Q#QaC#Q.E.E.5ap.5#5aEbc#S#H#C.TbTaraR.Va0#.a1#O#Qbw.v#J.vbwaCaCbfbw.E#O.z#N.AaLaN#y.E.EaC#Qbw.vbh#J#Q.E#O.TaTaJaebvbvaObybGbiaybH.E#Q#Q#m#Q#Q.E#Q#Q.E.CaA#A.ubF.taHb0.g#E.E.E#QaC#Q#m#mbw#QaC.RaFa9btb5.x#5aj.C#S#2.Zap.5.5#QaCaC#Q#Q.E#Q#EaEb0a9#haHaWaF.9.5#Q#Q#Q#m#m#m#m#m#QaC#Q.OaFaWbG#P#PaL#NaAbJ#Q#m#m#maCaC.vbfaCbfbw#Q.Eb9.A.SbZ.l.l#PbYaZ.x#E#6.2#5#5.2#5#y#E.R#y#E#yb5#y#yb.bv.l#y#5#ybHbH#E#y#EaS.DaQ.2#Ebs#h.t.l#O#daJ#Ma1#O#QbwbwbwbwaC.v.v.vaC#QbfaC.5aCbwaC.x#F.A#q.l#4bx.u.u.z.zaX.u#2.MaO#ybvb5#R.MbXaL.ibF#PbJ.E#O.E#Q#QaC#Qbf.5.5.5.2.5aqaQaF#A#H#PaZ.lb5bMa4bP#N#C#w.2.E#Q.EaC#QaC#Q#Q#Q#O#R.P#A.tby.9b5ar.Z#H#AaybHbH#Qbwbw#Jbwbw#Q.Eb..g.P#M.rad.u.g#O.E.E.EaKbwbwbw.fbw.EbHb5#s.a.uaE.lbMbMaObe.WaM.t#y#O.xbybP.S#f#Xb6a0#c.n.xaKbw#J#J#Jbwb3.Eap#O#3#XaIa2.qaiaxaTaA#ybHaKbw#Jb3.3bAaCaC#m#Qapa8aJ.S#Dbvaj#ya6#f.7#7bv#QaCaCaC#m.vbfaC.5.5bf#Qb.#F.7#ibW.n.V#I#I#ha8ap.5.EbwaCaC#Q#Q.E.Eayav#Naz.saO.l.lbxbLbu.N#e#O#Q#m#QbA.E.5.EbHaq.t.A.p#q.H#d.zaF.k#5ajaDajaDaDaD",
"#6bQb3aD#o#6#6aDaDaDaDaD#6##aD.2#6#6#6#6#6#6#6####.2##.RbS#S#S.8#EaD.R.RaG#C.Xar#F#IaM#D.xaKbwbwbAb3b3bAbwbwbf#m.v#mbw#Q#Qap#waLa9a7.H.9a7bIaH.t.Z#0#db9.t.t#Da7bebTa8#s#saE#Ra8#gbF#sae.HaZbX#a#S#R.x#Q#Q.E#Q.EaCaCbA#Q.EaC#Q#Q.Eaq#gb0#I#h.M.n#pb6bua1#O#Q#J#J.v.vbw#Qbfbwbw#Q#O.zbIaAbJ.E#Q.E.E.5#Qbw#J.v.v#m.Eb5#DaTaG#d#y#OaObv.z.YbX#y.Ebw#Q#Q.v#maC#m#maC.E.l#s.u.Ybi#S.C#O.E.E.E#m#maC#m#mbw#Qapae#2#Hae.R.x#y#y.laXaW.TapaC#maC#m#m#m#m#Q#m#Q.E.C#vaHaWaF#4.5#QaCaC#mbh.v#m#mbl#QaC.E#s#A#k.M.H.l#eaHbIay#Q#Q#m#Q#QbfbfbfaCbfbwbw.E#g#..S#Fb5b5.z.P.gbv.x#E#5#E#E#E#E#E#Eb5b5b5#y#Eb5.g.T.VbZ#e#d.l.xbv#Eb.bTbTaq#w#Eap.gbY.zb5#yaZ.W.Abrap#Q#mbw.v#m.v.v.vaCbwbfbf.5bf#QbA.EapbZ#Mbrb5bvbv#ebF#PaX.taXaE.H.la8.M#sab#R.H#R#PbPaWaA.g#y.E#Q#QbwbwbA#QaC.5#Q.5.E.EaqaQaL#AbP#eaOby.haVbP#ebH.E.E#Q#m#Jb3#maC.E.E#O#P.p.p.z#y#ybTbTbT#D.Y.Tap.E#QaKbwbwbwaK#Q.E.x#Oa8aGbIadadaz.gb..E.EaK#J#J#Jbw#Q.E.Eapaq#saH#H.gaq.HaZ.W.SaJaZb.#ObM.t#Nazb2.I.J.SaVbxbvbH.EaKbwbAbAbA.E.5b.b7.Jbua0.Laiax#M.t.l.E#Q.fbf.3bAbfbA.5bA.E.x#d#K.S#Fb5#5#y.sbLbq#jb5bwbw.5bfbfagagbfbAbAbf.E.x.Vb6.G#7.caz#M#C.Xap.E.EaCbwbw.v#Q.E.E#O.MbI.A.J#3byaP#V.q#Za0#..sbH#Q.vbwbfbfbfaC.E.E#w.PaT.Wa4aOa8.P.#.O#5.BaDaD#5aD",
"bQ#6aD#o#6aDb1#Y###o#####o##aD###o#6#o.2#6b1######.2aDaD.R#8.i.XaD#6##.9#D#Hae.H.c#kaT.t#ybwbwb3b3b3bAb3bAbAbwbfbw.v#maC#Q.5.R#v#A#Darar#e.u#H.zaeaZ.T.T.zbZ#D.z.zae.X#s.MaNa8aqae#DaFau.ZaOar.T#AbG#w.E#Q#QbAaC#m.v#QbwaC#m#m#maC.EapaqaF#N#k#p#ba0#ibx#O#Q.vbh#J.v.vaCbfbwbw#QbH#P.P.H#Q#Q#Q#Q.5.E.5aC.vbwbw#Qap#4#haW#D.lb.#y.lar.z.YbG.C#Q#Qbw#J.v#magbf#m#m#Q.E#y#P.aaA.Cap.E#Q#Q#m#m#Q.v.vbw#m.E.x#D#N#Dar#yb..x.xb5.t#N#F#O#m#m.v.vbh.v.v.v#m#Q#Q#Q#E#P.t#w.5#Q#m#m#mbh.vbh.v#m#m#Q#Q#E#D#I.P#dbvaO#dauaWaQ#Q#Q#m#QaCaC.v.vaCbw#m#m.E#g#I#M#FaO.l.z.Pbs#E#y##.2#EaD.RaE#s.M#s.M.9b5#d.g.haV#M.SaV.h.sbTaO.9aea7#s#sae#E#Eae.W.z.lbv#eaJ#Ia7#O#Q#QbwaCbw.v.v.vbw#QaCaCaCaCaCbwaKapbZ#MbZbv#ybpa8.gaq.9bTbT.X#s.MaEaQbt.zab.zaZaraebZ.uaH#P.x.E.E#QbAaCbfbfaC#Q#Q#Q.E.E.EbJaAbi.W#3bWbL.p#q#O.E.EaK#J.v.v.v#J#J.E#Q#O.zbIbP#e#y.x#y.Rb.#saW#Db5ap#Q.E#QaK#QaCbA.5.5apapbTax#u.rbz.WaZ.x.Ebwbw#J#JbwaC.EbQ.xapb.aN#aaHb9aZbY#NaJaebv#Obv.Ma9#I#Far#dafbP#B.u.z.X#EapbQ.x.2.Eap#E.g#jbI.Aaz.L#7aJ#N.t#y.EaKb3bfbf.3b3bAb3aKaK.E#d.J.SaGb5bJ#yaeasbq.J#4aK.fbAb3#Jb3.3bAaKbAbA.E#O.c.7#i#b.d#..p.z#E.E#QaC#m.v#mbl#Q#Q.Eapa7#I.A.pbNbPaxbNbLbu.G.Nbx#O#Q#m.v#m.v.v#Jbw.E#O.M#k.A#7#d.9.#aF.8#5#5aDaDaDaD",
"#6#6aD#o#6aDb1#oaD##aD#o#####o##aD#6#o.2.2aDb1aD#6#6.2.2##bcb0aN#E.2.2.RbcaHaeaO#eaJ#B.t#E.EaKaKbwb3bAaKbAbAbfaCbwaCaCaC.5#Q.2bt.YaX.l.l.H#v.tbMaO#R#s.z.z#s.z#Dbt.Z#db.b.b5#y#Ob5b5#wbYb0a8b5aZ.P.YbF#y#Q#m#m.v.v#m#mbwbw#mbw#m#m#Q.5.5aq.Tazb#a0a0#.bx.E#Qbh.v.v.v#mbw#m.vbwbw.EbSbS.E.E#Q#Q#QaC.5#Q#m.v.v.v#Q.E.gaH#I.z#y#O#y.lb5#ebG#2.k#Q#m#QaC#m#m.vbfaCaC#m#Q.E#5#zbJaC.E#Q#Q#Q#maC.v#m.v#m#Q.E.H.PaT.zb5.xbH.x.x#y#D#MaG#y#Q#m#m#m#m.v#mblbw#Q#m#Q#Q.x##bHaC#maC#maCaC#mbhbh#m#m#QapbsbY#IaG.HbvaOar#7bIaQ.E#Q#m#m#QaC.v.v.v#maC#Q#Qay#I.AbZb5.l#D.Pae.R#E.2aD#6#EbS#saL#h.za6b2bObNbN#FbZao#K#p#K.J#j.c#e.Z#F#jbY.T.R.R.ZaH.zb5b5a7.p.p#e#O#Q#m#Qbwbw.v.v.v.vaC#Qbfbwbw.vaC.Eap.T.S#DaObvbv#sbZa8.9b5.9.g.M#gaq#E#y#y#w#s.t#eaOara1.paHaN.E.E#Q.E#QaCbfbfbfbA#Q.E.E#Q.E.CaAbIazac#u.h.H#O.E#QbwbwaC.v#Jbwbw#Q.E.l.taTau.H#5#5.x#E.RaeaH#h#wap.EbwaK#maCaCbAbAaC.E.E#Ob9az.r.rbu.W#ebv.Ebwbf.vbAbA.5ap.2.5.5.xaE#2.u.W#u#Ib9b.#O.x#e.u.Y.P.n.9ba.Ib9bOaAav#C#F#F.tbZ.T.T#D.t.u#B#B.j#AbG.PbO#P#R.xbHb3bw.3bA.3bAbAbAbAaK.EbT#jbq#pa8bJ#5be#X.7#X.gbQ#Jb3#J.f#Jb3b3bAbA.faK.x#qb#b6#ibubuazaE.E#Q.EaC#m.v#m#maC#m#Q.E#4.M#s.M#P#Pay.Mbx.Mb9.M.8#Q#m.v.vbfbw#Jbw#QbH.E#4#CaTaH#q.l#gb0aE#EaD.xaDaDaj",
"#6#6bQ#6aDaD#6aD#o#6#oaD#6#o#6#6aD#6aD#6#6#6.2#6#o#6aDaD#EaQ#2#s#E#E#E.2#8#a#eaO.n.h#N.t#y.EaKbAbAbAbAbf.EbAaCaCaCaC#Q#QaC.5.5b8.aaL.g.l#y.zaLay.lbv#yb5aqaE#8#8#D.T#D#gbT.Rb5#y#yb5bTaX#2#sbTbTbZ#M.u#R#Q#mbh.v.vbfbfaCaCaC.v.v#mblaCaCapbT#7#ia2a0#..M#O#m.v.vbwbw.v#m.v.vbw#maC.5#Q#Q#maCbf.vaCaCaC.v.v.v#m#Q.E#g.paHb9bv.xbH.x#ybM#v#2ay#Q#Q.E#QaC#maC.v.v#m#m#m#QaCaCbw#maCbwbw#mbw#maC#m#Q#m#Q.E.gav.A#P#ybHbH.x#Eb5#D.A.tbv#QaC#m.vaC#mbwaC#m.vbf#maCaC#maCaC#maCaCaCaC#m#m.v#m#m#Qap.ZaH#IbZ.lb.bp#daGbI.M#Q.vbw#Q#Q.vbhbh.v.v#m#Q.E.M#N.AbZaOar.T#hae.R.2aD#6aD##b5.9#D#F.nai.Lb#.r.N#t.n.Iat#7.JbU.rbu.VaR.s.h.h#gbT#E#g#2#P.laObxbIaHae#O.E.E.E.E#mbw#J#J.vbA#QaCaC#J.vaC.E#O.TaT#FbTaOaO.T#Db5b5a8#gaE.Rb.#E#y#O#E#y.RaG.PbyaO#d.h#B#v.l.E#Q#Q.Ebf.vbf#maCaCaCaCbw#Q#O#R.Wbua0bubObv.EaKbwaCbAaCaCbfbA#Q#Q#O.laAaT.VbM#y.x.Ob5#E.X#CaHae#O#QbwbwaCaCbfbfagaCaCapapb5#7bubu#i.razae.x.EbfbfbA.5.5.5.5aKbA#Q#5ab#Aad#ua1#y#O.x.gav#B.W#3#0.s.hbY#F.ga8a7#F#7#FaG#K#IaT.AaTbI.ubFaX.z.M#4bv#ObHaKaKbAbAbfbAbAbAbAbw#JaKbw.OaGbq#cbe.O#y.X#K.7asb9.E#J#J#J#Jbwbwbwbw#JbwaK#Oa7#Mb6#i#ibu.h#dap.5aCaCaCaC.v#maCaC.E#Q.E#O.E#O#O.E#O#Q.Eap.E.E#Q#Q#QaK#QaK#Q#Q#Q.E.Ebv.HaA#NbIa7bp.gaFaQ#E#E#6aDaD#6",
".5b3#6#6#6#o#6#oaD.2#6#6#6aDbQbQb3aDaD.2.2#6#6#o#6#6#6aD#5aQaH.T.R.2b.#E#8#2aeaO#daG#N#D#yap.5bwbAbwbAbAbfaCbAaCbAaC.5aCaC.5.5###S#AbF.laO.gbPaAa8a8b9bt#s#sbt#8.Tbt#v#Dbtae.O#y#Ob5.lab#AbF.9aO#F#..A.M#Q#Q#m.v.vaCaC#QaCaC#m.v.v.vbfbf.Eb.b2.7b6a0#..M#O#m#m#m.v#Q#m.v.v.v#maC#m#Q.E#m#mbfbf.v.v#mbf.vbh.v.v#Q.Ea7bI.pae.x.xbH#Obv.HaA.aay.E.E#QaCaCaC.vaC.v.v#m#maCbw.v#m#m.v#mbw#m#m#m#m#m#mbwaC.E#gavbIbFbv#QbE.B#E.R#F.A.tbv#Q#maCaCaCbf#m#m.v#mbfblbfbfbf#m.v#maCaCaC#maC#m.v.v#m#Qapb9#k#M#Dbvb.aO#d#j.A.M#Q#Q#m#Q#Q#m.vbh.v.v#m.E#O.M#AaT.t#0aO.zb0.X#E#EaD#6aD#E#yb5#3#pbDbDasaI.r.rbUao#t#t.h#fbu.Sa0.G.Lacaz.hbrbTb.#gaHbxar.l.z#Nav.g.x#O#O.E#Q#Q.vbw.v#maKbw#m.v.v#J#Q#Qap.T.A.taRbpb5.z#Db5.XaX.TaEaEaEaq#O#E.R#Eb.a7#H.TbMbM.zbI#2ay.x#Q#Q.EbAagbfbfaCaCaCaCbfbw#Q#ybObu.ra0bO#O#Q#QbwbAbAbAbfaCaCbA.E.E.CbP.A.t.H.O.x#5.O#y#d#j#I.Map#Qbw#JbfaC#Jbw.vagbA.5apb..z#ubL.Laz#uaJ.gbH.EbAaC.5bAaCaC.3bAbA.E.O#P.p.h.H#O#ObybG#B.p.zara4.haT#B.u.Z.9bp.9.Z#DaG.PbYaubF.z.Mby.x#O#O#O#O#O#Oap.EaKb3b3.3b3bAaKbAb3aK#J.f#yaxbq#b.Z.Oaja8#j.7#r.Z.2bw.f#J#Jbw#QbAbfb3#JaK#O.TbRb6.m#9#i.Vb5ap.EaCaCaCbfbfbf#m#m.E.E.l.k#Pbx.M#P#P.M.M#P#s#s.May.M.MaQaQbcb8#zab#P#PaAav.p.t#4aO#e#vaE#E#EaDaDaD#6",
".EbA#6#6#6#6#6aD#6#6#o#6#6#o#6bAbQ.2#6#6#6#6bQ#6#ob3aDaD#E#z#H#D.R.R.R#EbtbG#e.H#VbY.j#Db..E.5#Jb3bwbAbwbwbfbfbfbfaCaC.5#QaCbf.EaQ.A.W#VaO.H#FaJa7bsa7.z#ga8.R.R.R.R.R.8#8#SaEb5#ybT#y#s#N.zb5ar#7#MaV#e.E#Q#Q#maCaC.5#Q.5aCaC#mbfbf#maC.Eapb2#ia2aI.Abx#O.E#m#mbw#Q#m#m#m#m.vaCbfaC#maCaC#m.v.v.vaC.v.v.v.v#m#Qapa7#A.p.sbv.x.x#ybvaZ.PbiaQ.E#Q#QaC#m.vbf.v.v.vbwaC#maCaC#mbwaC#m#m.v#m#m#m.v.v#m#m#Q#g.p.pbO#ObHbH#E#Ebp#D#M.tb.#Q#Q#m#mbf#m#m#mbf#m#maCaCaCbwaC.v#maC.5aCaCaC.v.v#m#Q#Qapa7aV#M.tbvbvaOb7#jaTaQ.E#Q#Q#Q#Q#Q.v.v.vaC#Q.E.E.M.A.A#F#0#d.P#k#Da8#E#E#E#E.R#y.lba.J.rbBa.a0a..r.N.L.c#q#7.J#r#b#ia.a.a0.G.J.sb5aO.T.pa7bMar.zaTaH#e.g#P.o.C.E#Q#Q#Q#m#maCbAbfaC.v#m#Q.Eap#s#I#jaZbvb.btb0#eaE#g.Caq#z#saQaS#E#E#E#E#4#vbYb9aOaZaA#NaA.lbH.EaCbfbf#mbfaCaCaCaCbw#Q#Q#O.s.Ga0#ua1#O#QbwbwaCbfbfbAbfbfbw.E.E.CbP.A.V.H.R#yaD.Ob5.9aGaW.M.Ebw#J.vbwbAbf.v#Jb3aC.5apb.bx#u.N#3.s.WaW.u#w.E.E#QaK.5bAbfbfbfb3.E.E.O.g#4#O#Oa8aG#N.AbF.H#d.h.AaJaF.s#daZ.T#vb0#a#vbt.k.l.x#O#O#O#O#O#Ob5aeaX.zaN.xaKbQb3bAb3.3b3bAb3aKaKbHb5#jaI#fa1.Oaj.8aG#M#fbr#ObH#J#J#JaKbAbAbAb3b3.Eapbr#.b6#9.m#i.tbMap#QaCaC#m.vbfbf#maC.E#OaSbG#A.p.h#FbZ.V#F#FbZbZbZ.T#FbZbZ.tbF.#bcaXbFbFbO.zbx.H.Hb9.T.Maq#E#E.xaDaD#6",
"aC.2aD#o.2#oaDaDaD#o.2#6#6aD#6#6#6#6#6#6.2#6#o#6#o#6aDaD#EaEaL#D.R#E##.Rbt#H#ebT.s#kaM#D#O.5bw#JagbwbfbwbfbfaCbf.Ebf#mbfaCaCaCaC.O.PaWauaZ#0bsaG#hb9.9b.#y.R#E.2.x.R.2.2#waFaFaqb.aObs.P#Haeb.bs.J#M#j.9ap#Q#maCaC#QaC.5#Q#QaC.v.v#m.vaC#Qapa1a0aIaI#.ay.E.E#QaCaC#m#m#m.v.vaC.vaCaCaCaCbwbw.v.v.v#maC.v.vbhbf#Qap.M#k#I.TaO.x.xb5aOb9#2.YaE.E#Q#m#mbw.v.v.v.v.v#m#Q#Q#Q#Q#Q#Q#Q#Q#m#m#m#m.v.v.v#maCaCae.p.A#Pbv#O.x#y#EbpaG#IbZ#O#Qbw#m.v#m.v.v#maCaCaCaC#Q.5.Ebwbwbw#maCaCbA.vbhag.vaC#Qapa7#M#M#Fbv#yaO#d.h#I.M.E#Q#Q#Q#Q#Q#m#m#m#m.E.E.E#s.AaT.V#0.c.p.Wa1.Tae.R.x.R.9aOae#p.Na0#Z#bbb.dacbN#7#Vaf#t#t.qaoawa2.1.ma.bLaGbraZ.tavb9aO.H.V.AbIbZ.saAbiab.E.E#Q#Q#Q#QaC#mbfbfaCaCaC.5apaE#kaHb2aO#O#s#2bcb5.x#O#y#E.Obc.DaS.2#E.R#E#gaHbraO.lbO#Aav.M#OaK#m.vaC.vaCbfaCaCbAbf#Q.E#Obx#.bu#uau#y.E#Qbw.v#mbfagbfbfaC#Q#Q#yaA#u#7bT#yaD#E.R.Ra8#ha9.M.EaK#J.vbwbAbwbw#JbfaC.Eap.R.tbI.h#V.Ha4.P#Bb0.C.E.E.Ebw.vbf.vbf.5#Q.Eap.E.Eap#y#D.A#k.t#dbM.caJ.ha6bM#4.z.P#H.i#1#xaj.x.x.Eap.x.x#O#O#w.zaFaH#B#B#v.ObHbQb3b3b3bAbAaKbAb3aK.Eb5#pbq.7.z.O#5bJ.t.7#Mbr.x.EaK.fbwaKbAbAbAbAb3.Eapa7bRb6a2.m#ibP.g#Q#Q#Q#m#mbh#m.vbfaCaC#Q#5#v.Y.p#F#0#0beatbZa6b2b2b2b2b2a6b2b9.g.lb5.H.HaO#0.H#ebZ.tb9aq.R.x#EaDaDaDaD",
".2#oaD#oaD##b1b1aDaD#oaD#oaDaD#6#6bVaD#6#6#oaDaD#obVaDaj.2.XaL#DbT.2#E.8aFb0bsara6#kaT.T#O.EaC#Jag#Jagbfbfbfbfbfbf#mblaCbf#mbfaC.E.CaLbi.Paearbs.taF#s.X#ybHbH.x.2aDaD#E#E.6aL#waO.g#j.ua6bpbTbZ#IaJaeap.E#Q#m#maCaC.5#Q.5#QaC#m#mbfaC#Q#Q#4.h.raI.raVb9.E.EaCaCaCaC#m#m.v#m.v#maC#5#5#m#Qbw#m#m#maC.v.v.v.vaC#Q.Ea7#I.Aa7b5b.#yaOaO#s#I#2aN#Q#Q#Q.v.v#J.v.v.v.v#m#Q.EbH#w.8#Q#Q#Q#Q#Q#m#m.v.vbh.vbfaC#w.W.AbObvb..x.R.R.9aG#I.T#O#Qbf#m.v#m.v#m#m#maCaC.5.E.C.X.E#QbwaC#m#maCbfbh.v.v#m.5ap.Z#I#M.t.lbv.lba.W.p#e.E#Q#Q#Q.E#QaC#mbfaC#Q.Eap#g#AaTaJa4a6#7a4b9.J#DaOb.b..H.s.W#u.r#ba#.qa#.L.LaobN.h.h.catbL#bbm.m.1.1.mbL#i.A#CbNbO#daO.s.W.AaVbO.H.z#a.M#ObH.E#Q.E#QbwaCblbfbfaCaC.5.5.8b0.A.VaObvaNbk#s#yb.ap#y.x#E#w#vbX.8.x#E.Ra8#F.taZ.lby.P.AaA.l#QbwbwaCbfbfbfbfaCaCaC#Q.E.E#P.r#u.r.p.g.Ebw#QbwbwbwbfagbfbwbA.Eb.#D#M#7ar.R#E.2#y#y#daF#I#s.Ebw.v#JbwbwbfbwbwaCbA.Eap.gavbIax#dbvbM#eb0.YbG#R.E.E#Q#mbfbAbfbf.EbA.E.E#Q.x#gaH.A.V#d.H.s.P.V.nara4aA#2b0aQ.bbEaKaKbQ.2ap.2#O#E#O.g#HaTaH#C#k#BaFb5.2bA#6b3.3bQ.3bAaKaK.EbQ.R#F.S#M.V#5#5.O#F#I#Ibrb..E.Ebwbfbwbf.EbwbfaKbAapa7#.b6.1.1#ibI#PbH#m.EaC#mbfblbfbfbl#m#Q.Eb4.u.A.Jbe#dba.haH#7atbr#q.V.J.Jau#q.Xb9bx.zbZbObW#3a4.z.s#gaeb5#E#y#6aDaD#6",
"#6#6aDaDaD#YaDaD#YaDaD#6#6aD#6#6#6bV#obQ#6aD#6#o#6#6#6.x.x#waF.T.R#E.xbT#v.P#daOaf#r.A.T#O.5bwag.vbfbwagbfbfbf.vbf#m#m.vbf#m.vaCaC.E.8aLbi#Haear.9.ZaGaFaEb5.x.x#y.2ap.R.R#DaHae#3#C.ha6#dar.Z#CaH#gb.aCaCaC.v.vbfbfaCaC#QaC#Q#maCaCaC#Q.C.t#u.ra0aIaVayap.E.EaC#QaC.v#m.v#mbw#Q#Q.k#1#5#Q.E#Q#m#QaC#mbf.v.vaCaCapa7aW#Ia7b..R#Ebp.9#7aWaF##aCaCbwbf.v.v#JbwbwaC#Q.E#OaN#a#S.Cap.E#Q#Q#m#m#m.vbh.vbf.5#E#D.A.h#d#O#O.Rb.b7#h#I#PapaCbf#m#m.v.vaCbfaCaC.5ap#4aLb0.C.E#Q#Q.5aCaCbh.v.vag#maC.5a8#h#IaubM#OaO#qaH#C#w.E#Q#QaC#QaCaCaCbE.4#z#w.x#dbrbZ#F#3aiafao.J.L#eaOarb9.PaJ#.bL.r.N#c#Z#b.d.G.N#.#N#N.W.h#X.Gaaa5.F.F#9bm#X.J#ubIau#qbO#X.AacbObe#d#3a6.gbTaNaN#E.E#QbAag.vbfaC.5.5.5#Q#E.t#N.VbM#O.H#vaX.l#yap#yb5.x#y#1bkay#y.x.xbp.Z.PbxbMaObx.AbIay.Ebw#Q#mbwbf.vaCaCbfaC.E.E.lau#uazaz#uaA.l#Q#Q#Q#Qbwbf.vbfbf#Q.E#O.T.A#j#d.R.x#E###Ea8#C#2#g.E#Q#J#JbwaC#maCbw.E.E.E#y.t#N.W#eaOaO.H.laebP.YbG.C#Q#Q.fbwbwaC.5aKaC#QaKbH.XbP.AaH#earb9aJ.h#V.HaZ#C.YbG#w#O.EaKbHbQb3#6bQ.5.2b.a8#haTaHb2b2aJ#I#v.R.2.E.3.3.3.3bAbAbA.3bAbQb.at.S.SbZbJ#y.l.V#Mb#.Tb..5.5bfbfbfaCbfbfbAbf.E.2a6#faIa2.m#i.AaA.C#O#Q#QaCbf.v.vaCaC#m.5aC.x#saHaW.Pa4ar#3br#q.ca1.s.Z.ca1#3#e.z.PbI#I.p.p.p.W.V.s#d#g.z#w.x.x.x.x#6.x",
"bQ#6aD#6#6#oaDaD#o#6#6.2#6#6bAb3#o#6#6aK.5bQ#6.2aKbQ.xbH.x#waF.T.Rap#Eaq#DaF#dbp.Z#r#M.Tap.Ebw.vag#Jbfbfbfbf.vbf#mbfbf.vbf.vbfaC#Q.5.5aq#s#H#CbrbsbTa8.T.t#v#saN#waq.R.9.XbY#IbY#j#7be.9bebr#C#Hae#E.5#m.v.v.v.v.v.vbfbw#Q#Q.v#Q#Q#QbHaN#SbiaJbD.d#MbI.M#O.E#QaCaCbfaC.v#mbwaC#Q.E.o#2#S.C.E.E#O#Q#QaCaC.vaCaC.5.EaEa9#Ia7bpb.b.bpbe#C.YbtbH#QaC.vbw.vbwbwaC#Q#Q.E#4.z.u#B.Y.Pa8ap.E#Q#Q#Q#m.v.v.v.vaCbQb9#I#A.s#E#Obpbpae#HaW#sbQaC#maC.v#mbf#maC#Q#Qap#w#h#NaTaF.O.EaC.EaC#m.vbhag.vbfaC.5.R#D#N.u#e.l#dau#k.t#y.E#Q#maCaCaCbfbfb3bj#1#1#s.Xarba#3bWbD.db6#i#p.0.Vau.p#u.W.h#XbL#ib6aIa..G#X.N.AbPbO.z.Iba.qa3#n.F.1.1.m.d#tau.Jax#t.h#.#u#7baafbOa4ar.H.H#g#P#g.X.EaCbfagbf.5.5aC.5.E.E.obI.h.Hbv#y#PbXb5b.b.#O#ybvb..g#Sbcb5#y#yb..HaG.t.H#0aZbN.YaA.ObHbw#QaC.vbfbfaCaC#Q#Q.E.MavbP.0.sbP#A#P.l#Q#Q.EaKaC.v.v#JbwaCap#g#IaH.Z.R#E.x.R.R#g#AbY.C.Ebw#J.vbfaC#Q#Q.E.E.EbSaX#2.u#e#0bM.s#Dbsb5#ebPbibG#RbHaK#Q#QbwbA.EaK.E.E#wb0aT.Wb9.Ha4.WaJb9araebP#NaH.g#O.xbHbQbVbV.2#6.3.2.5.2.XaLaWaJ#7#jaVaT.t#ybQaKbfaKb3.3bAbQb3bAbQ.5#E.T.S#MbOby.lbMaxb##Mbr#ObQaCbf.3bfbAaCbAbfb3.5.E.ZaVb6b6.G#i.AbI#v.l.E.E#QaCaCblaCbfaCaCaC#Q.xaN.P#I.Pa7brbZ.tbYbY.h.VbZbZ.VbY.p.paua1.sa1.J.A#N#C.gb5bFbc#O.x.xbQ#6bQ",
"bQ#6#6#6#6#6#6#6#6.2#o#obA#6.2bQbQ#obEaK.2bQ.5bQ#6#6#6.x.x#waL#D#y#E#Ea8aF.P#dara6aV#I.Tap.E#m#J#JbwbAbfaCbfaCbf#mbfbAaCaCbfaCbfaCaC#Q.5ap#waG#H#Cbrb7.9ae#D#DaE.X#w#wa8aebr.t#7a6b7bsbZ#H#2aF#w.5aC#m#m.vbhbhbh#J.v#m#Q#Q#Q#Q#Q.Eb5#sbk#AaA.saR#7b##IaE.E#QaC#Q.5#mbwbwbw#Q#Q#Q.E#s.Y#BbGbx#4#O#Q.E#Q#m#mbfaCaC.E.9aF#IaF.9#Ob.bT.TaW.u#w.5#Q#maC.vaCaCaC#Q.E#O.XbGa9.P.taFa9bYaE.R.E.E#Q#Q#mbw.v.vaC.E#4bY#B#ha8.R.Rbp.TaW#H#wapaCaCaCbfaCaCbf#Q#Qap#w.P#N#k#IaW.z#E#Q#Q.5aCaC.v.v.v.vaCaC.5.RaL.Y.Wau.Pa9b0#w.E.EaCaC#m.vag.vblaCbAbQ.8b8#sbs.caJ.GaI#la..Fb6.G.r#M.paz.V.0#7bWbD#ia0aIbLa##3bO.g.laO#0.Iaoas#9a2.Faaa5#i#cbW.0#3.V#p.Jac.LbW#t#r.WbZ.t#F.za7aE.gbHaC#JbfbAbA.5.5.5.5bHay#AazaZbv.laXbG.z.M.M.M.M.M#e#eaAb0#eb5#y#ybv.MaH#qaO#0a1#Aa9ay.EbH#QaCbwbw#mbf.5.5.E#4bPav#q#0#0.sbP#A#v.C.E.E.E#Q#Q.vbwbwaC.E#4aF#kaFa8#E.RaqaqaF#B#D#E.Ebwbw#J#Q#Q.E.E.E.E.CaF.a.u.sar#0.sbY.paGbsbM#e.u#BbG#R#O.E#QaK#Q#Q.EbH.CaL#N#ka6ar#e#C.A#7.H.l.z#NaT.VaO#O.xbH.fbV.3.3bVbV.3bA.2.2#wbt#v#h.tbZ#D.X#O.E.E#Jb3b3b3aK.3bAb3bQbA.2.TaTaM.Wauauaxaz.r#M#F#E.2.5bA#JbAbA.5bfbAbwaK.EaE#rbR.G#XbNbLaTbI#P.l.E#QaCaCaCaCbfaC#m#Q#Q.EapaqaQ#vaL#2#Aa9.u#H.u#AbI#AaH.P.z#ebTbv.Hb9bN#uaT.PaZa8#vbc#E.x#6aD.bbH",
"b3#6#6#o#6#6#oaD#6b1aD#6aDaD#6#6#ob3#Y#6bQaD.2bQaD.xaDb5#y#w.P#DbTb.#yaE.u#h#darb2#I#Ia7ap.Ebl#mbwbwbwaCaC#mbfaCaCaC#maCbfaC#maCaCaCaC#Q.5.5.R.Z#D#C#haGbrb9.9.laqaqaq.8a8#4.Za7.T#DaLb0#v#z##.E#Q#m#m.vbh.v.v#J#Jbw.E#Q.E.E.E.C.T.P#2aA.M#dbpar#7.raH#w#Q#QaCaC#QaC#m#Q#Q#m#Q#Qap#s#BaT#M.AbNa1bM.E.5aCaC.5.5.5.5apa8aLaHaGbt.T#D.ub0.X#O.E#Q#Qbw#QaC.E.E.E.8#D.uaH.Va8arb7a6#H#k.ta8ap.E.E.E#Qbf.vaCap#OaeaH.aaFaE.X#gaH.Y#s.x.5bAbAaCaCaCaC.5bHb5aEb0bG#Db9a6#H#2#D.9ap.5aC#maCag.v#m#maC.5.5.C#v#2#A#CbF.Xap.5.EaC#mbh.v.vbfaCaC#QaC.Eap#w#F.Wb#b#a0a2a2a2.FaI.N#X.V.VbO#V.nar.VbqaI.ra0auai#Vby.l.Hbe#jbUbqa0.1.Fa5#nac.LbD#7.VaJ.JaJaz.N#X.Jb##u.A.paHa9bY#D#PaQ.4#obf.5.5.5.2.5.EbE.4bG#Na1b5aOae.z#D.z.za7#P.zb9#ea7.tb9ae#sayaqa8.P.h#daO.gbP.YbFb..E.E#Q#QbwaKaC.E.E#wbG#AbF.Hbv#0#0b9.ubI.P.z.C.E.E.Ebwbwbw#Q.E.2.8#ha9#v.X#waE#8aHb0#wapbHbw#Q#J.E.5apap.OaEaLaW.P#ebTb7br.ta6bZ#C.hbybvaN.u.Y#C#wap.E.E#Q.E.Eaq.PaTaVb2#0#daGaJ#I.h#db5.M#2#B.t.lbvbHaKb3bV.3ag.3.3.3.3.3bAbQ.x.Oaq.Rb.b.apbH.EaKb3bwb3aKbAbAbQbV#6bQ.2ae#C#k.hbFaz#ua0.S#M#F#E.EbAb3b3bAaKbAaKb3bwaK.Eae#k#u#.#t#Vax.N#..p.t.H.E.E#QaC#QaC#m#QaC#Q#Q.E.E.E.OaE#s.o#s#s#s#P#s#s#s#g.H#Ob.b5aZauaV.p.PbZ#e#ebX#v#R.xaDaDaDaD#6",
"aD#6aDaDb1aDaDaDb1aDaDaDb1###6#o#o#oaDbE.5aD###y#6.x#5#E.x.gbY.tbTb.#waFaW.t.9ar#F.A#kae.E.E#Q#m#m#Q.EaK.E.E#QaCaCaC.5#Q.5#QaCaC.vbw.v#m#QaC.5ap.RaNbtbt#v#D#D#D.#.6bX#8.##vbkaLbXbtbcaSaj.E#m#m#m#Q#m#Q#m#mbwbw#Q#QbH#EaN.z#s#HaH#j.T#dbM.Hb9#F#raMaG#y#Q#Q#Q#Q#Q#QaC#Q#Q#Q#Q.E.Ea7.A.S#Mb#b##.bY#zbJ.2.5.5#Q.5.E.E#O.X.z.P#aaL#8bt#w.E.E#Q#Q.E#Q#Q.E#E#w#s#h#HaG.Z.H.HaZ#d.9b9.ta9#a#s#wbH.E.EaK.vaC.Eap#EaE#v#abkaL#H#haQaqapaCaC.5.5#Q.5.E#yaN#v#2bGaeaObTb5bs#CaWaFae#E#Q.5.EaCaC#maCaC#Q.5.Eb5ae#g#w#E.E.E.E.EaCaC.v.vbfaCaC.E.E.E#Oap#yae#F.J.G#ib6a2#WaaaY#p#7.c.sbear.na1.Nah.N#p.L#7.VbPaubx.za1#F.h#7#7#X.ma..m.dbD.LbWbO#7bN.p.N#X#..r.r#M.AaJ#FbrbYbY.t.iab#5bQ.5ap.5apbQ.EbH.lbX#Bav.tbZ.T#qb9#eaZaZbeb7#d.Har#d#d.g#saQaQ.M.z.Wa6aO.l.zbi.uae.xbH.E#Qbwbw.E.E.8aFa9.tby.lbMbx.s#d#3.zbP#NbP#s.C.E.E#Qbw#Q#Q.Eap#waQaF.Dbt.6#v.Ta8#Oap.E.E#Qbw.E.2bT#g#h#2aH.taZaO.H.ZaGa7#d.Z#C#I#va8b5#eaJ.j#Ca8ap.E.EaK#ybFbI.A.V#darbr.Pa7.T.P#e.9aZaF#A#Ha7.l#O.EaKaK.3.3.3.3.3.3aCbAbHbHbH#O#Ob.bTbS.x.xbHaKaKaKaK.EaKaKbQb3b3.2#E.Xbeb7#daxbua..r#M.Tb..EbAb3aKaK.E.EaKaKb3#QbHbM#7#M#u.Jax#tbW.L.G.p.P.T#wap.E#Q#Q#Q#Q#Q#Q#Q.E.E#Q.E.E.E.Eapap.E.E.Eap#O#Oap.Ha7bZ.W.A.Wbr#d#d.M.z.M.C.x.E.x#6#6aj#6",
"#6#6aDaD#oaD#oaDaD#6#YaDaD#Y#6.2#6bE#6#6.2.x#EaD#E.2#E#y#O.X.uaH#D#P.M#saXaeaObe#C#M#Ca8ap#Q#QaK.E.E.E.E.E.E.E.E.E.EbA.E#Q.E.E#Q#Q#Jbw.vaC#Q.E#Q.5ap.5ap.O.XaQ.z#sbc.#aXbc#s#PaN.l#O#O.E#Q#Q#Q#Q#Q#Q.E#Q#Q.E#yaSaQaQbtaF.uaHaG.ta6.9ar#e.t#j#C#p#FbZby.E.E#Q#Q.E.E.E#Q.E#Q#Q.E.Eap#4a7#7#c#X.G.raT#Ab0.#aQ.8ap.Eap.Eapap#Oaq.Xa8b5ap#O.E#Q#Q.E#Q#5aSaQ.6b0#H.ta6ar.H.ZaGaG.ta7.9.9#g#8#Hb0btbtaSbH#Q.5apap.5apb5aNbc#s#g.9apap.5#Q.5.5.5#EaNbc#v#ab0aX.gb.a8#P.gbpbsaGaH#H#v.XbH.EaC#m.E.E#Q#m#Q.E.E.Eap#Oap#E#w.R#Q.E#Q.5aCaC.5ap#E#R#P#s.T.z.taG#K#.aIa2a5aa#nbC#F#ea4.H#d.Mau#I#I.J#7.V.V.hazaAbP.u.z.TaG#FbZ#3bWac.r.rbz.raz.h#7a1#q.cbW.c#7.N.N.h#pa1aZ.Hb9.tbO.z#Rap.xapapapapap.E#ObH#R#P.tbF.T.z#Da1.zbZaGaGbO.t.VbZauaGb9bM.laN#v.z.h.W#db5.g.P.YbP.HbH.E.E#Q.EbA#EbtaW.P.n.lbMaXbP#FbO#q#0aZ.zbP#2aL.#ab#x.x.E#Q#QapapapaqaEaE#w.Rapap#Oap.E#Q.fbJaQbtaLa9#2.tb9#dbvb.bTbsa8.9.Xb9br.t#P#4b5.9.ZaJaW.tb5.E.EbHayav.pao.n.Ha6aGa6.9.9#DaF.Z.9aebt.u#2.t.g#E.xapbQ.E.5bQ.5.2.EbH.EbH#O.Oay#s#vaL.##z.O.EbHbHbHbH.x.2aK#6#6bQapb.bT#3.Las#i#fbnbZa8.x.xaK.EbHbHbQ.E.EaKaKbHapb.#dbOax.havaz#paoat#F#C#2.Pbtbc.C.x#Q.E#Q#Q.E.E#Q.E#Q#Q.E.E.E.Eap.Eap#O#4#g#saA.p.A.W.tbeaZ.zb9.g.X.O.E.EbHbHbHaK.xbQ",
"#6b3aDaD#6#6#o#o#6aD#o#6#oaDbA#6#6#QbE.2bH.x#E#E.x.2#O#Ea8.T#C#h.T#s.gb.aebF#Db0#I#h.Z.Rap.E.E.E.E.xap#y.8aEaQaQbcbcb8b8.o.ob8#1#1.o.o#1#1#1.obcbc#s#s#s#s#s#g.Z.Zbeb7b7#daraOaOb5bvbvbv.lbMbyay.M#P#P.zbc#P#v#a#2.P#8.t.Taebe#3b7bT.R.T#B.jaJ#3#darb5b5.l#yaq#4bT.RbT.Ob5b5b5#ybvarararbaao#f.r#N.u#vaF#2bk.6#s#s.M#4#O#Ob.#O#O#Ob.#O.l#RaQabaQ.#.iaLaX#DaearbsbZ.T#q.T.M#s#s#s.T.XbTaE#DaF#H.i.6#1.oaEa8bT#O#O#O#O#O#O#Eb.b.aqaEaQbcbcaF.iaF#Dbt.X.lae.Tbt.T.T.Ma8#da7.t#2#HbcaQ#w.xbH.E.5#Q.Eap.E#O#da7.TaF#a#gb.#O#ObHap#O.H#e.h.PbF.PbI.Y.A.AaJ.h#Xb#.G#na3.L.s.9.H#dae.zaA#CaGa6at#7#7bN.W.tbO.ta7a7.t#DbZ#q#V.cbNbN.J.W.W.Waua1a4#qauaf#V#7#tataG#Fb7bT#0b9bPaua1bx#e#g#gaeaEae.X#Raq#ybvbvbvb.aO.9#dbsa4#ea7b2b9a1.taJaT.P#4#E#ybF.z#qaH#PbM.lae.p.A#Pb..EbHbH#QbH.CaLaTaG#0aO.g#aau#e#F#FbOa7aZaZa7.taA#abk.#ab.o.oay#Rb5b.#O#Obv#O.9ae.Z#sbc.o#1.D#aaL#D#DaebTb5#d#g#P#D#8#8.T#8aG#D#qb7b5aO#d#3#CaTaGaq#O#ObJbG#BauaPar.Z#C#7#db.b5aSaQ#Da7.g.CaN#vaHbY#D.T#g#w.Rb.#O#O.R#waE.MaQ#P#v.uaF#v#vbkan#SabaE#4#yb..x.x.x.x#EaSaQ.TaGaV.S.r#Xb2.narb.#O#O.xbH.xb.b.#O.x.xbH.x.xbvaOar#0#Vau.A#u.JbabTbe.T.T.i.a#a#vaQ.MaQ.M.g#4.Rb.#Ob.b.b5a8b9.M.T#P.T#h#k#AbP.tbOaea4br.P#h.Xb5#E.xaDajbH#6#o.E#6aD",
"#6#6bQ#6aDaDbQaD#6#6#6aD#6aD#6aK#6bQaKbH.2#E#E#E#E#OaqaE.z.T#g#dar.g#D.tbG.u.t.tbra8b.#yaE.Tbc.#bc#s#8aFaFaL#SaFaFbX#v#v#8#vbXaX#vaFbXaXaXbF#D#8aFbt#D.t#DaG#j.h#K#K#K#KbD#j#7#F.V.V#F#7#j#K.WaJ#C.PaF#v.t.t#D.za7#wa8.Zbt#sa6#D.t.ZaO.X#v.P#H#C#p#7aGaAaAaAaA.PaFaFaFaFbXbX#v#v.t#FaG#7#7aJ#..pau#eb5.9.Mbtbt#8#vaLaAbXaXaX.z.zaX.z.z#v.uaL#vbX.z#sa8.9bsa7#Da7#Da7#daOb5#OaqaEbcaEaQ#s.X#d.X#D#v#8#S#h#haG.TaX.#aXbX.zbr#D#8#v#S#S#v#Dbt.Mbsar#d.Ta7#g.zaNaqaN#s.T#g.X.9ae.T#8aFaF#D.Tbcbc#1.o#1bc.tbYaH#C#2#BaH#F#Fa1a7bx.Vbn.G.r.Naf#3.zaG#CaG#F#F#7#p.Jasao.n#d.H.9.CbSb5#w.gbsaZb7#d.n#ea1bOa4aeb9.X#4bTbT.l#0#daR.n.n.naZbsbsbybeaG.A.J#qb7b7#3#F.P.h#e#d#0a4.J#ub#.N.h.VbOauau.tbO.z.zab#P.T.zbF.z#D.t.taX.t.tbZ.z.tbPbPb9#d.Ha8aAaX.H.zbP.M.l.H.z#k#kbZ#4#ObH.Eap.O#haT#F#0.l#e#P#Pa1.c.V.haua1b9.c#e#d.M.zbXbXbXaL.uaL.taX.zaXaX.TaGaH#CbY#v.#bXbc.MbsbT.R.Ra8#P.P.uaLbX.6b8b8#8btaFbY.Pa1bsbebYaT#C#w#O#O#4#S.YbPa4#0b7.t#j.Z#d#y.R##.Raebt#8.#.Xaqb9#D#DaG.P#h#F#D#D#D#D.t#D#D.taX.z.M.Cb5.C.gbX#vaL#2b0.t#D#D.zabab.#.i#aaFaG#k#M.SaJaG.tbZ.tbFaX.zbF#D.t#D#D.z.#.#.#aXbF#FaG#7au.W.A#rbZ#darae#DaE.Xbc#v#vaA#abi.aaH#CaG.tbZbZ#F#j.W#k.A#I#r#j#7#Fa1b9bx.zb9bZ#2aL.XaD#y.x#E#5aDbE#6#6aDaDaD",
"bQbQ#o#6#6#oaD#6aD#6aD#oaDaD#6bQ#6bE#6#E.2.R#E#E.RaN#DaF#s.9.Hb9aG#H#CaXbc.X#y#4.z#Dbt.tbYaF#8#v#v#DaFaG#s.Z.ga8.9.9.9aq.H.C.Xae#gb9bsbsa8.X#4#4aqb5.R.9.9bsae.Za6br#F#F#F#F#F#F#F#F#F#F#F#F#7br.Zbs#d#d.Za1#D.z.M.g#4aNbtaQ#w.X.T#Dbc#wb5#4a7#F#D#F#D.zaX.t.t#F#FbZ.z.T#s#PaX.z.z.z.V.t#FbZbObx.n.g.z.t.T#ga8.Ra8aE#PbFbFbFbF.tau.t.tbF#P#eby.H.g.T#Db9#e#h.YaH.gbp.R.R.O.O#E#5.xbS.obt#g#s.T.T#g#wa8.Z#D#D#DaF#vbX.tau#DbZ#D#s#g#waqa8a7.zb2a4.s.ta7.9#E.x.x.xbSaE#saEbt#s#d.9bs.T.t#D.t#vbXbKbK#Sbi.A#jb9#e.t.p.rbg.rbubu.m.F.F.m.m.d.Lafa4.ta7a7aGb2#V.cazbWaO#y#E.R#ybH#E.R#E.9.9.H#qbx#q.s.n.HarbT.9a8aq#E#4#e#4.l#0.Hb9#daO.laraObZ.A.A.h#dara4.sb9bZ.taG#eaR.La0a.#i#cbW#3#q.VbN.hbZ#P#sbt.z.z.t#vbF.t.t.t.tau.tbO.VbZa4.H.g.z.z#s#RbM#RaX.Pa7.H#d.zaJ.A.P#RbHbH.Eap.X#CaJaG.s.C.l#4.sb2b9.gaZa4#qbZa4b9.t#P#e.HbMby#P.z.z.tbF.zbFbF#D#Fbrae.H#4.Cay.zaearb.a8#vbIaA#P.CbH.EbQ.2apapaqbx#CbI.h#C.A#H#w#O#Oaq#v.Y.u.g.9#d.zaHaFae.9.R.R.O.R##aqaE#sbc.z.Tae.H#dae.TbZ#D#D.t#Da7aZ.9.9.X#g#s#saE#g#P.Mbyb9aGaGaGaGaGaF#vbF#v.tb9.gaZa6#7#jaG.haG.taGau.taGauaG#j#jaGaG#v.DbX#Sau#F.h#pauau.t.Zbsa7#DaFaX.g.C.MbX.z#PbFbO.VbF.taG#F.t#FbZaG#FbZ#F#F#Fb2br#FaeaZ#gaA.P.z.M#w#E.x.2aDaDaD#6bE#6#6#6aD#6",
"aD#oaDaDaDaDaDaD#o##b1#oaDb1#6#6#6#6aD###E.R.Rae#8#Hb0aEbTae#7#k.u.t.g#O.x.gabaFaA.z.t#D#ga8b5#w#P.T.taF.T.T#g.9#4.Hb5.lbT.9#d.gaebebsbsa8a8#4aqbT.O.Oaq#w.X#g#s#s#s.T.T.zaXaXaXaXbF.z#D#D.TbZa7b7.9ar.HaZbr.z.z.M#R#y#y.xap.x#E#y.Xbc#RbJ.X#g.Tbr#F.T#P.z.zbratbZbZ.T.z#P#PaXaX.z.zbF.zbF#P#P#eby#ea1bF#Da7a8.9aE#PaXab#P#PbFbFbFbF.tbO#P#gbsb7bsbFaA.P.z.MaX.t#sbcaQ.ObS###5#5.x#5.O.O#4#g#D.Taea8ae#g.TbZ#D.##P.M#P.za1.T.T.TaX#gbT#d.M#D.h#jbZ.Tb9bTapap.2.xaDb5#y#w.z#gaea7.TbZa6bs#gayaq#5bJ.C#sa7.g#dar.H#t#i.Q.Qa..1.FaU#U.F.Qa.asaxafa6br#ea8.H#q.W.AbOb5bTb5b5bS#E#E.ObTaqb5.9a7a1.tbO#qa1ae.9ae.6aE.C.CaN.gby.g.t#H#j#s.g.H.HbZaTaV.V#VaR.VaJb2.H.z.W.h.0.q.1.F.1#i.dbN.h#r#.#K#3.9b5b5aq.Xay.M.M.z#P#P.zbO.zbF.t.taG.zbF.Pa7a8.l.O.O.H.M.t.zae#da4aGav#aabaSb5apb.bsbZ.haAbF.#bF.taGbFbF.t.t#q#dar#eau.Wa1by.g.g.zbF.zbO.zaXbFbF.T#Fa6aZa8bJ.CaAaHa6ar.R#e#2.u#R#O#O.E.EbH.5.5.Eap#ybxbI.A#N.u#Rb.#O#R.t#A#H#e.9.9a7aF.taL#SaNaq.9.R#EaD#E#EbT.XaQbtaEaq#R.MaX.z#P.z.z#P.z#s.ga8ae#s#s#s.M.MaX#Paea6#F#F#7#F.z.z.zaX.z.t#P#gb9ae.TaG#D#vaA#vaFaG.taGaG#7aG#jaGaAaA#vaAaA.t.t#p#7.t.t#s.g.g#s#DaEb5bv.C.MaX#P#e.H#0by#e.z.z.z.z.zbx#Da7a8bT.9#daea7br.g#e.M.M.M#4.xb..xbH#E#E.EbQ#obAbE#6bQ#6#6",
"#6aDaD#YaD#Y#6#oaD#ob1aD#6aD#o#6#6bEaD#y#E.X#D#haH#HaebTbs#haWbY.X#Oap#wbFaH.jaHaebvaOaebF.T.g#4#g#s.T#D.T.TaE.9b5.Raqb5#y#y.R#Eb.bp.Rb.#O#y#y#y#y.x#y.Oaq.CayaQ#gaQ#s.#.#bt.#abbcbtbcaX#D#s#g.Z.X.9aObTaOb5aZ.M#sabaE#5#y#y.x.x#y.2.x.O.CaS.M#s#s#D#D#saX#P.Mbx.Ta7.z.TaQbtaX#PaXaXaX.MbFbF.MaybMbv#yb5b..R.RaqaEaQabaX#P#Pbt.z#P.zbF.z#s#ea8a8aE.T.MaQaQ#4.xb5#wbc#z#z#1.4#EaD.x#E#y#y#E#Eb..R.R#y.8.Z#s.TbtaQaQaQ.M.M.M#P#s#s.Taeb5.9aN#s#s.Mae#e#gaQ.X.x#y#y.x.x#Eb5#yaq#saFaF#DaeaeaE#w.C#5.xaj#y#E#E.O#4.s.J#ia2.1.1.F#G.U.U.e.Fa5.q.ca6#e#d.9aObMbZ.AaMax.n.MaE#g#8aNbTbT#4#4.9bTar#V.c.V#C.u.T.9.X#vbk#8.C#y#R.M.t.pazaGbZ.Tbraf.Lbz.G#c.LbDbL.N#qaR#q.h.N#Z#n.1.F.F.1a.a..r.r#M#ka7bTb5b5.O#RaE#g.M.z#P.TaL#H.tbF.z#CbI.t#s.tb9#4b5.x#y.lbvae.t.t.M#daRb9.tbG#a#v#s.Z.9bp.9#e#PabbFbFbZ.z.t#v.Wav.saraObyaA.zbM#4#e.Mab#P#P#P.#aXaXbF.T#ebs#4#y#ybX#2#sb5b.#s.abG#R#O.E#O.E.E.E.E.E.E#ObMbxbO.z#R#Obv.g.Pbi.ubr.H.9.TaFb9a8aEbcbc.6aNaq.R.RaD#E.Raq#yb5.O#y.CaQab#P#PaX.z#P.z#Pae#Raqb5b5.Ob5aqaqbTa8#g.T#D#D.T#P#s.#.#aXaXbtay#wa8#g.Tbt#v#v.##v#vbFaG.tbt#D#D#D.t#v.#bXbX.t#D#D#D.zbF#s#waqb5#yb5.x#y#E.xbv#y#ybvb5bM#Ray#Pay#P#s.M.M#e#RbTb.b.aO.9b9aEaE.o.CbH#OapbHapbQ.5.2#6aKbAaKaKbQ.x#6bQ",
".2#6aDaD#6#6#6#6##aD#6#6#6aDbA.2#6.E.xaS#g.T#D#DaH#F.9aOa7#A#N.z#O.E.E#ebY#kaTaHa6bTbv.M#2.P#wb5b.bp.R#y.x#y.R.x.x#EaD#EaD.x.R##.R#E#y#E#E#y#y#y#y#y#O#y#y#yb5#y.x#5b5#5#yb5#y#E.R#E.x.R.R.Raq.R.X#s#s.TaEa8#waQ#sbtbtbc#R#yb5.O#y.x.x#E#5.x#E#y.x#E#y.x.x.xb.#y#y#E#y.x#O.x#y#y#y#y#y.O.kab#R.O.lb.#y#y.x#E##.x.2.x.x#E.x#O.x#y#ybv#yaqaN#P#z#waE.o.C#E#y.x#y#E.2aD##aS#1b4aN#1aQ.8#E#E#E#E.2#O.x#E.x.2.2.2.x#y.x.x.x#yap#E#y.OaE.MaN.XaE#g#w.x.x#5.O.kaQ#gbt#w.R#E.8b4.8.8aNaN.8aq##aD#5aDaj#5#5#6##aD.x##.8aE.t.L.db6#W#G#G#GaU.F.Faw.0#q.c#e.9.laO.nax#.#uaxaZ#P.zbFaA.taF#D.Za8.gbr#j.J#c#r.A#2#s.9.R.X#DaFaG#g.H#qav#M.J.nb7#F#7af#ca..1.1.Q.Qa.#c.I.I#t.d.ma..Q.F.F.F.F.1a.bgaV#jaG.Zb5#y#5.O#5#yb5b.#EbT#4ae#g#4b5.9.z.P.XbMaXaLaE#y#y#y#O#O#ya8#sa7#g#Db9aO.g.z.zb0aHaF#DbFaX.M.X#d.9.X#e.zau.u.ua7.laO#w#vayb5#y.x#y#y.x#5#y.x.lb5#y#yaqaq.9#ybvaN#abt.lbM#RbG#AbX#4#O#O.E.E.E.EbH.E.E.Eb.#y#Ob.#RaX.uaH#h#g.9.X#D.t#gaq##bS#EaN#8btbtaEaq.R#E#E.R#5#5#5#5#y#5#y#y.x#yb5.Oaq#w#s.Maq.R.Ob5.x.O.O.O.Oaqb5#yb.#E#y.Ob5.O#y#5#ybS.O#E#####ybSbS#Eaq.O#y.8bS#Eaq.O.R.O##.O.O.O.R.Rb5b5aqaEbtbcaQ#w#y#y.xap#y.xbH#y.x#O.x.x.Eaj#y.x#y#y#Obv#y#Ob5aN#say.XaEaybSaj.x.x.2bQ.2bH.E#6#6aKbEajbQ.2#6bQ#6aD",
"bAbQ#o#6.2#o#6#6aD#6#6#6#oaD.2#6.2.x.8#8aFaN.R#daF#hbsbpaZbY.Y.u.gb.ap.Rbe.V#.ah.h.9aOaZ.P.P.T#D.z.##8btbc.6.6.o#zb4.4.8aSaSb4b8b8aQ#s.6aXbX.##P.#aX#P.#btaQaEaEaN#waS#w#w#x.kaEaQbcaQbcbt#gaN#waNbcbc#1aE.O#y#y#E.O.CaQaE#zbX.6.kaNaS.CaS#waSaE.kaN.k#RaNaNaNaN#R.C.CbJ.O.C#R#waNaQbtaQaQbt#z#w#zabbcay#wbS.O.x#E#E.xb5.O.OaNaQ.6bcaN.gaybc.k.O.x#y.x.x#5#E.x.xbH#EaD.2#E##aNbcaQaSaEaQbcaQaS#5#5#5aD.xap.x.x#y#5#y.CaQbcaQaN.8.XaQaEaq.x.xaj.2.x#5#E#EbSaE#8#saN.CaSb4.8aD.2#E#E####.2aDaD#6#5aDaDaD#o#6aD#yb5#daP.q.w#U#U#GaU.Faa#n#nao#t.cbO#7#q.n.0.J#ia0ax#0.H#w#e#e#P#h#HaA.T#v.uav#I#kbNaG#sae.9.9#dbsae#D#vaEaeau.pbNbaba.Zbsbabb.Q.F.F.F.Q.1#ZbC#Tbm.m.1.1.F.F.F#G.F.Q#ibNb2#d.R#E#y.x.x#5aj.x#5.x#E#E#E#E#y#E#Eb5aSaebTaZ.M#P.zaEb5#E.x#E.R.R#yaqaEaX.T.z#D.g.l.g.z.tbF.taA.PaFaFaFaG#Hau.taub9#dbT.gaFaF.C.O.O.x.O.O.Ob5.C#zbcab#sbXaF.Maqb5b5aqaQ#v.Ma8bT.g.P#A#S#P#R.x#O#O#O.EbHbH#O#O.l.M.z.P#A.P.Ta8.9aEaF#vaNaq#E.O.O####.R.4bc#gb4.6.6#z#w##.O.O#E#5#5#y#5bS#R.o.##gaNaQ.M#sbc#saS.O.O#y#E.O.O#5.O#E#ybS.C.kb8aS#5##.O###5#5####.O.O#5##.R#y##b5#5bS##aD.ObS.O.O##.x#yb4#1.6#8bK.6#saE#zbcbcaEaS.O#y#5#y.xaj.xbHaj.x.xb5b5#w#sbcaQ.kaEaQaEb5#y#EbH.2bEbQ#6.2#6.2bQ#6aD#6.2aD#6#6#6#6#6#6",
".5#6#6#6bQ#6aD#oaD#6#oaD###obQ.2#Ebp#8#H.X.R#EapaEaL#8#4arb9aG#k#C#D#D#D.taJ#raG.Z#0b7.zaG.z.TbF#DaX#8#8bt.6#1bc#zaNaS.8.8#xb4#zaQ#sbtbt#DbXaXabbFbXabbXbFaQaEaE#w#RaS#w#RaNaNb4bcbcbcbcbt#g#waqbS#E.x#E#5.xaD#EaK#y#5.xbS.k.##1aEaNaN#w#waS#w.kaNaN.k.CaNayaNaNaS#RaS#w.C.C#w#w.k#sbcaNaq.O.RbSaEabbc#z.4.8#y#E###5#E.O.O.O.kbcbcbcaNbS.x#y.x.x.x.x.x#y#5.x.x.xbH.2#E#E#E.x.2.R#E.RaNbcbc.oaSbS.O#y#5#y#5#y#y.O#yb5aSbcbcaQ#w.R#y#y.x.x.x.xbH.2.2aDaD#E#E#E#waQaEbJ#EaD#E.2aD###6aDaDaDaDaj#6b1aD#EaD#6####.R.9#qaoaY.F.F.F#G#G.Faaaaa..d#t#7az#u.G#X.d.G#ia..LaO.Ha8#d.9#db7.M#vaA#vbF#P.z#q.sa7a8.9.9.9.Z#Fbearb9.z#e#ea1.P.haea8.9ba#X.Q.Q.F#G.Fa..m.ma0.1.Q.Q.F.F.F.F.1.Qa.#c.n.9bp#O.R.O.xaj#5bE#5aD.2#E#6bQ#6aDaD#5aD#E#yb5.Ma7aO.g#vaQaq#y#E#E#5.xaD#E#E#w.T.Ta7.M.T.M#R.HbT.H.g#s#D.T.Ta7b7ar.Hb7.Ma7#gbtaEb5aqaqbSbS.O#5.O.C.kbtbcbc.i.a.#b5b5.Ob5#4aEaX.zae.l.gaX#vbGaLaXababab.o.oab#PaXaG#H.P.t.Taea8ae.T#sbc#w.Oaq.2aD#####E.2#E####aNb8aQb4.C.b##.O.b####.O.O.8b4aQ.6aQ.8#E.OaNbc#saSbS#w.k#z.6.6bc#1#z.C.CaN.kaQ#x##aS#z.ob8#zaE#zb8aQaNb4aEb4aEb4b4aEb4aSaNb4b4aE#w.R.8aEbcb8aN.O#y.O.8aN#1.#b8aNbJ.ObJ.4bJaS#x.4#x.b#y#ybS#wbcbXaQaS#y#E#y#y#E#y.xbQ#6#6.2aK#6aD#6aDaDaDaD#6#6#6aD#6aj#6",
"#6bQ#6#6#oaD#6#6aDaD##aD#oaD#6.2#E.9#haF#4.R.x#E.Ob4.##vae.9#db9aG#v#D.taG#Fa6.9b7.T#Dbt.X.O#yb5.O.R#y.Ob5#y#E#E#E.R#EaD#EaD##aD#E#E.R#E#y.Rb5#yb5b5#y#yb5#y.R#y#Eb5.O#y#yb5#y#E#y#E#E.R#E#O#E.R#E.x.E.E.xaD.x.x.EbH#5#5.x.x#5aD.x.x#E.x#E#E#O#y#Eb..x.E#O#O#y#y.x#O.x#yb5#y.x#y.R.x#E#E#E#E#O.2#E#E.xb5b5.xaD#E#E#E#E#E#E.x#O.x.x.xap.x.x.x#y#yap.x#y.x#5#E.xaD#E.x###y#E#E#E#y.R#y.x#E.ObS#5#y#y#E#y#yb5#y#5#E#y#E#y#E#O#E.x#E#E.xbHbH.2.2bQ.x#EaD#E#E.R#y#g.M.R#5.x#yaD#EaD#6#6aDaD#oaDaD#6aD#5.x#E##aD##.C.g.h.r.Q.F#UaU.e#G#G.F.Q.Q.Gbn.q#ca0a.#l.Qa..Q.Kbn#0.H.M#v.t#D.T.taFa7.H#4by.Hby.sauaGbr.ZaRbab2bebTar.g.g.HbMae.z#s#wbT#V#Xa5.yaa#G.F.F.Q.Q.Q.F.F.F.F.F.F.F#W.m#iax#dbp.R#E.2#5aDaj#Yaj#6aD.B#o#oaD#o#6aD#5#5#yb5.C#Pae#y.l#waQaQ.o.8.O.O#y#E#Eb5aqb5#E#4#sbt#s.g#4#waE.T#8#D#D#D.T#sa6bra7#s#sa8#y.R.O#y.O.8#5#E#5#5#y.x.ObT#yae.ibtb5b5#E#E.Rb5#w#P#s.M#Pbs#4ae#P.zbtaX.#bXbXbXaXbF.ta7bs#0ae#D.T#s#s.8#E#6.2aD#6aDaDaDaD.2.2.2#E#E#E.2#EajaDbJ#5#5bSbS#5##.O.x.O.O#E.x#E##.R#E.2#y##.8.k.obc#1.6bcaEaSbS#5.O####bS#x#zb8b8b8#z#z#z#z#zaE#z#z#zb8b4b4#z#zb4aNaE#zaS.8.8bS##aq##.R##.R#5b5.ObS#y#5###y.ObS.C#x.k#x#xbj.O.O#y#E.O#E#5#y.xaj#y#E.x#E#6aDaD#6#6.xbE#6#6.x#o#6#6bEbQ#6#6bQ#6#6",
"bQ#6aDaDaDb1##aD##aDaDaDaD###6aD#E.9#D#h#w###yaDaj.xbSaQ#g#g#F.T.T.M.Z#gbr#DaGbZa7.MaybJajaj.x#6#y#y#y.R#E#Eb.b..R#E.R#E#EaD#E.x.2#Eb..x.x#y.x.x.x.x.x#E#E#E#y.2.xbv.xb5#y.x#y#yap.x#y#E#E#O#E#E#E#E.x#E.xbH#E#EbH#E.x.E.x#E.x#E#E#Ob.#E.R#Ob.#E#O#yb5#O#y#y.xbv#y#Ob..R.x#y#Eb..Rb.#Eb..R#E.Rb..R#y#y#5#E#y#E.2###5.2#E.x.x#y#E#O#y#y#y#y.x#E#E#5.x#E#5##.xaD#EaD#y.O#5#E#y#y#yaD#Eb5#5#y.O#5#y.x#E#E#Eb..x#E#O.xb.#E#y#O.2#O#O.xbHbQ.x.E.x.2#E.2#E#E#E#E#E#w.g#4.H#y#y.O.x.2.2aD#o#o#6#o#6#o##.2#EaD#E##.8#w#ebN#i.1.F#G#G#W#W.F.F.F.Q.Q.mbCaw.m.F.Q.Qamam.Q.L#d.9#s#v#vaG.tbZb9aZ.H.H#V#e.sbx#FaG#K#p#p#7#7#F.c.say#e#4.H#w#gbc#waqa4ac#Zawaa.F.F.F.F.F.1.F.F#G#U#U.F.F.1#ibDb9.R#E##aD#6aDaD#Y###6aDaD#o#Y#YbV.BaD#5.x#5.l.C.g.g#yb.#y#5#yaS.ob4#z#s#w.Rb5.R.R.R#O.RbT#yb5#yb5#4aN#Pbtbtbt#8.TbZaFb0#saOb5.Rap#E.R#EaD#E#E.xaD#y#E#Eb5#E#Oaq#8aLae.R.Rb..x#E.R#y#d#g#g#ga7.TaX.TaE.X#4.O.C.C.gb9a7brbrae#Db0.T#waDaD#6#6#o#o#6aD##.2.2aD.2#EaDaD###EaDaD#yaD.xaD.x.x#5aD#E#5#5aDaD#5aD.O##.2#5###E.O####.O###5#####E####.O##.O######bS##aDaD######.8bSbS##.8.8##############bSaq##.R####.8aqbSbSb5##.O#E.O#5.R###5#E#5aj#5#5.B.BbE.BaD.x#EaDbQ.xbEbH#6#6bH.x.xbQ#6#6bA#6#6bQ.2aK.E#6aDbAbE.2bQ.xbQ#6.E",
"#6#6aDaDaD##aD#oaDaDaD###o##aDaD#E#E.X.i.6aq#E.x.x.x.x.xb5ae#s#s#s#zaEaEa7#h#AaF.C.x.x#5.xbEbE#6.x#y.R#y#O.R.Rb.bpb..2#E#E.x#E#E#E#O#Eb.b.bp#E#Ob5#y#y#y#E.x#Eap.x#y#y#y#y#O#y.x#O#y#y#y#E#O#E.R#E#E#E.x.R#y#E#O#O.x#O#E#E#E#E.Rb.#E#Eb..R#E#E#E#E#y.R#E#y#ybv#y#y#E#E#y#y#E#E#O#E#E#E#E#E.R.R.R#E#E#E.R#E#EaD#E##aD#E#E#E#E#y#EbH#E#y#E#E#y#E#5#y.x.2aD.xaD.xaD.x#E###y#E###E.x.x.x#5.O#5.xaj.x.x#y#E#O#Ob..xb.b.#O#E#E.xb.#E#O.xbHaKaj.x.x#E#Ob.b..Rb.bpb.b..HaZ#eaZbMbv.x#y#E.2#6aDbA#oaDb3aD#6.2.RaDaDbS#4a8#7bu.1.F#U.e#U#U#G.F.F.1.F.Q.1.1.F.F.e.F.Fama.ao#0aq.8.Ra8aq.9b7a6aG#p.hac.N#XaxbWa6bea6#K.S.SbuaVau#q#e#R#Raq.##8aS#4#eaca.#W.F#G#U.F.F.1.F.F.F#G#G#U.F.1.1bL.c#0#y.R##aD#o#Y.B#6###EaD#o#6aD#obE#6#5.xbv.HaZ.g.H#ybv.xbv#y.x#y#y.OaEaEaN#s.T.X.R#E#E#E#E#Eb5#y.xbv#yb5#y#ybTb5.X.T#s#sa8#E#Eb.ap.x.x#E#y#E.2.2.x#E#6.x.x#Eap#E.X.6#vaNbp.Rb.b.bp.Rb.#ybT#4#g#Dbt#s#g.XaqbTaqbT.Xa7a7#D#haG#D#g.Oaq#E.2aD#Y#o#o#obVaD#YaD##aD.2aD#####5aD#5#5aD#yaDaD#5#5###5#6aD#5##.O#6aD.baD#5####.O.O##.O.O.O.O##aD####.ObS##aD##b1.b####aD####.8.b##aD######b1####aDaDbS##.bbSaD.R##.8bS####.O##b5#E.xaD###E#5#E.x#5.x#E#5#6.BbEbH.x#E#EaD.x.2#6bEbQaD.2bQ#6#6#6bHbQ.x#6#6#6.2#6bQbQ#6#6.2#6bE.2.2bQ",
"aD#6.2#6aD#o.2#6.2#6aDaD.5aDaD.2.2.2###w.6.6.8#y#E.E#y#Eap#y#Eap.x#y.x.Cbt.z.Ma8bv#O.l#ybH.x#y.x#y.O.R#waea7.T.T.T.Tbr#s#gbc.6bc#s#ga7#sa7#s#s#g.M.M#gaQ#g#g#g.MaEaQaQ#gayaQayaEaQaQaEaEaQaN#zaQaN#s#gaEaEaEaeaN.Xae#g#ga7aN#g#gaNaE#gaNaE#g.XaE#gaEaEaNaNaE.kaEaE.XaNaEaEaEaEb4aQb4b4#zaNaE#zaQaEaEaEaQaQb4#zb4b4aE#z.k#z.kaE.k#w.kaNaNaN.kaNb4aSaSaNaS#xb4.4.4aS.8aSaSaSaS.8.C.4.CaS#x.4.k.4.4aNaEaEaEaEaEaE#g#zaE#zaEaQaQaEaNaSaSbJ.C#wa8a8bsaea6bra7br.V.z.V.L.Jaz.h#q.H#y#y#5.2#6aD#o#o#o#YaD#6#6aDaDaD.R.g.Wa..F.F#UaUaU.F.e.F.F.F.F.F#G#G#G#G#U.F.Fa..m#7.9.R#EaDaq.R.Rbr#X#Xasbqa0aIa.buaJaGa6ba#FbubzbzaMaz#q.H.H#waeaQaE.Cb5a1.Ga..F#G#G#G.F.1.F.Q.Q.F.F#UaU.F.1a.bu.Va8b5aDaD#YbV#oaDaDaq###EaD#6#oaDaD#Eb.bp#3#F.JbNa1.s.g#4#4bMaq.Ob5#E.R.Raq#s#D.X#waEb8.6bcaQaN.C#4#4.CaEaQbc#1aNaEaQ.X.O.R.R.R##.2#E#E.2##aD.2#5aD#6aD#E#5#E##.R.R#w#saQbcaE.R.R.R.R.Ob5b5##aq.R.R.R.R.RbT.R.O.RbT#w#s#D#8.TaN.RaqbS##aDaD#Y#Y#o#Y#o#Y#YaD#oaDaDaD#5####aD.OaD#EaD.x#####5###5.xaD##aDaDaDbE#5aD#6aD######.b##aD#####5####aD.b##aD##b1##bS##aD####aD####.2#6aDaD##b1aDaD##aD#o##.b####.2aD#####E##aq#E#5.O.x.O#5#E#5#5#E#E#5.x.x#6ajajaD.x.x#5#EbHaD#ob3bE#6#6#6#6#6aD#6bQ#6#6.x#6aD#6#6aD#6#6#6#6#6#6#6#6",
".2#6##aD.2#6.2.2#6aD.2#6##aDbQ.2.2.2.2#EbS#zaNaEbc#g.Xaqb5.Ob5.CaNbJb5.g#s#e.Har#db9a1#Pa4.H.9#d.g#gaQ#Db0a9aWaWaT#kaF#DaFbt#8#8bc#s.TaQ#gbtaQaEb8b8#z#1b8b4#zaQaEbcb8#zaQb8#z#zaQ#zb4#zb8#xb4#zaEaQ#g#g#gaN.XaNaEaNaN#gb4aE#gb8.Xb4#gb4b4#zaNb4aN#zaEaS.kaE.k#zb4aNaNaEb4#z#zb4b4#zb4b4#zb4aEaQb4aNaEaQ#zb4aNaS#z#zb4#zaE.k#zayaSaE.k.C#z#g#wb4aE#wb4b4aN#x.4.8.4#xaS.4aSbj.8#xaSbj#x#x.4#x.k.4aS#zay.kaEaEaQ.oay#z#z#z#zbc.o#RaSaS.CaQ.M#ebr#F#j#r#.b#bu.rbu.ra.a.#l.K#ubN#q.9b5#y#6aDb1#6#o#Y#o#6#o#YaD##aq#D#Ma..Q#GaUaU.eaUaU.e.F.F#G#G.F#GaU#U#G#G.1#nbL.L#0#E#5.R.RbT.9.Z#Fata#.qbn#f.KbgaJ.Ta7.t#C.S.Kadbz.j.pbObya8#ga8.Rb5ar.Va0a..F#W.F.F.dbnasa.a.a..F#G.e#G.Fa.#uaz#eb5aDaDaD#YaDaD#####E####.2aD###E.R.9b7#K.Sbgbub#.p.JaubO#P#g#e#w.8#w.8bS##aq#EbS#z.6.6b8aQaNbS#w.C.CaQ.oaQ.#aN###y.O.O###y##.O#EaD######aDaD##aD#5.b########.O##aq.8aSaQaQaNb8bcaN.8aq#EbTaq#E.Rb5aqaq#E#w#zbcaE.XaQ.M.X.8.R##aq##.R#####6#o#Y.3##b1#oaD#o#6aDaDbQaD#5#E###5.x.x###5#E#5aDaDaD.x#6.B.b#Y#6aDaD.baDaD.b.baD.bb1aDb1aDaDaD.bb1###YaDb1bj#YaDaD#o##aD#ob1#6#6aDaDb1#YaDaD#Yb1.bb1bjb1####b1.b.4#xb4#z#z#1.6b8#zaSbSbSaD###y.xbS##bHajaDaD.O.R#E#####6aD#Y#6#Y#oaDaDaD#6aD#6#6.x#6aDaDaDajaDaD#6#6aDaD#6aDaD",
"aD.2aDaD##aDaDaDaDaDaDaD##.baD#6##aDaDaD####aqaEbtaQaE#4.O.H#w#RaN#R.H#ea1a6.0at#c#fb##M#r#p#K#XbY.PaA#D#D#D#F#h#C#Daea8aq.9aqbT.R#E.R.O#5#EajbH.x#6bEajaD#6#6.2bQ#E.R.x.2#E#E#E#E.x.2#E#5.2aD#E#E.2.Rap.2#E.2.2ap.2#E#Eb..2#E.R#O.2#E.x.x.2.2#5#E.x.x.x.xaD#5.x#y#O.x.x#E.x.x.x.x.2aD#E.2aD##.2#E#E#EaD.R.2#E#E#E###E.x.O.O#y#y#y#y.O.R.O#y.R.R#E.O.R#E#5##.x#EaDaD##aD##aDaDaD.baD#5.O#5#5#5#5#y#y.x#y#y#5#y.x#y#y.x#y#y.x#y.x.lbJay.z.za1at#7bLbRbqa.#la..Q.Qamam#G.Q.QbB#.aGbsb5.RaDaDaDb3#Y#Y.3bV#o#o####a7.AaI.Q#UaUaUaUaUaUaUaU.F.e.F.F#G.F#G#G.Fbm.0ao.J#e.R.O#E##aSa8bs#7#K#p#p.JbU#M.hb9#4a8#h.A.AbL.Jax.padbI.zbsbpbpar.9af.N.m.F.F#Wa2aa#tai.qacao.L#Tak.F.F.1a.a.bP.gbT#5aDaDaD#6#E##.R##aDaD#Y#Y.b.RbT.9#Fb#aIaIbqaIbqbub##r#CaGa7#waq.8bS####aDaDaDaD#EbS.Oaq.O#y.O#5.l.O.O#y#5#y#5##aD#5aDaDaD#5aD.b#5aD.b##aDaD#YaDaDaDaDaD#E#E###E.R##.R##.8aQ#1aN.O.OaSaEbcbcaQaQaQaSaD#waEb8aEbS#EaD#y#y.R.O.R##.RaD#EaD#EaDaD#o#6#o#o#6#6#6#6#6#6aD#5#6.x#5aD#E#yaD.x##bS#E#5aD.x#5aDaj#YaD.BaD#YaD.b.b#o#YaDaD#YaDaD#Y.b#YaDb1#Y##b1b1b1b1b1aD#YbjaD#YaD#Yb1#Y#ob1b1b1bjb1b1b1bjb1b1bjbj.4#x#z#z#1bK.ob8#x.ObS.OaS#z.C##.OaD#5#5#E.O.O#E#####oaD#Y#o#oaDaDaDaD#6aj#6#6bE.xaDaD#6bQ#6aj#6.E#6aDbEbH#6",
"aDaD####aD##aDaD####aDaD####aDaD####.2#6aD.2#EaD#E#Eb5b5bvbT#e#q.s#qbWaJaI#ZasaIaIbgbB.S#f#rbUbUaJ#H.ta6#d#0.9b7bebea6bZ.T.t.t.T#D#s#s.TaEb5#y.x.x.xbH.Eaj#5bQ.EbQ.2.x#E#E.2aD.2bQ#E.x.2#yaD.2.x#E.2#E.2.2apaD#E.2.2.2ap.2#6.2aDaD.2.x.R#E.2#E#5aDaDaj.x#6aD#6aj#5#E.Raqb5##.Oaj#5aDaD.OaD#E#####E###EaD.R#EaDaD##.O#5b5.O#y.l#y#E#yaNaE.8b5bTaE.XaEaEaq#E#5#E#6#EaD##aD#E##.2.2#5aD#6###5aD#5#5#E.x.x#y.x#y#y.x#y.x.x#5#ybH.x.O.lby.MbObO#t#p#c#faIa..Q.Q#G.F.F#G.e.e.eam...Ka0bNaZb5b5.x#6aD#obV#ob3#o#Y###Ea8#7as#G#GaU.UaUaU#U#U#G.e#G.1#G.Q.1.Fam.Q.Gbnacazau#R.Raq.O#w.X#w.T#h#h#C#h.t.z#RbJaq#4aea7b2#q.n.s.W.j.j.h#d.9.9b7at#raIa2.F.F#Wa5a3a#b7#V#qbW.Law#n#W.F.Qa..raz#q#RbT.O.R.2#y#E#EbS###6bV#ob1.b.RbT.Z#X.SaIbg#lbq.7bq#faV#Ka6bs.Rb.##.O.xaj#5aD#5##.R#E##.RaqaEaQ.Xaq#y#y#y#E.xaD###6#EaD.x#6aD#6###5aKaj#5aD#5.bbEbE#6.xaD###EaDaD###E#E#E.2#####5.O.O.8#zb8bc#sb8aEaS.8####aD.xaj#5aD#EaDaD#E.R.R.R###E#E.R###E####aD#####6aDaD.2aD.x#6aD###EaD#E.2###yaD###5###5#5.x#6#5###5.BaD#Y#Y.b.b#YaD.B#Y#YaD#YaD.BaD.baDaD.b.b###Y.b.bb1###oaDb1#Y#o#Yb1#Yb1#Yb1b1aD#Yb1b1aD#6b1.baD##.baD####aj.O.O.x####aSb8aS.xaD.C#z.k.8#yb.#E.R#E#5aDbEaD#o#6aDaD#6#6aDbQ#6#6aK#6#6.Eaj#6.E.2aK.E#6#6bQbQ",
"aDaDaDaD#6aDaDaDaDaD.2.2aDaD#6#EaD.5.RaDap.xaD#O#E#O.Ha7#q.c.J.GbR.Ga2.Q#l.Fam.QaIa0bL.Ja6#3b9.Zb9a7#qa4#d#d.9bpbaaG#C#haG.TaFaG.tbZbF.za7#saEb5b5b5#E#E#E#O.x.2.x#EaD#E.2#E#E#EaD.R#E#E.R#O#E#E#E#6aD.x.2#6.2aDaD.xaD#6.2aDaD###yaD#E#EaD.O##aD.xaDaDajaj.xaD#5.8#g.MaNaQaN.Oaj.x#5#E#5##.2#E###EaD#E#EaD#E.2##.O#w#zaNaE#R#4#R.MaN#w.z#s.9aE#Dae.g#8#s.O#E#E#E#E#E###EaD.2.2aD#E.x##.OaD#E#E.x.x#y#y#y#O.O#z.k.Cay.C#y#y#y#y#O.lbv#0.n.n.c#bbL#ZaI.F.1#U.1aBaBaUbo.e.e#G.F.F#l.r.JaeaO#y##aDaD.2aD##aDaD.R.Rbp.0bm.F.e.UaUaU.e.e#G#G.1aabm#Zbbbb#c.da.a.a0.r#u.Wbra8b5#yb5##.O.8aqa8#4b5bJ#5#5.b#5.8#w#wbs#q.tazaV.W.Pa6ar.9.Z#7bq#l.Q.F.F.1a2.m.G.JbO#e.c.NadaI.F.F.1.Fa.a.bL#7.n.9.9.R.RbT.R#E.RaDaD.B.B.B#5#ybs#j#M.S#r#pax#7atbZb2br.Zar.R.9aqaE.6aQ.Cb5#y.X#gb4#g.8bT#s#v#sayaNaNb5.x#yaD.x#5.x#6.BaDajaj.xaDaD#5aD.xaD#5aDaDaD#E#5.8b4b8b8.X##.O.2aDaD#E#5#y.O#y#E.O#waEbcaEaq##aq#E.O##.b#5#6#5aDaD.O.R##.8aE#s#g#w.9.R.2aD.8######aD##.baDaDaD.2.RaD#E.OaNaN.8.8.O.Oaq.RbS.C#x.k.O#6aDajaDaD#5#Y#5.b.b#Y#5.bajajaD#6.baDaDaD#####6#6aD##aDaD#6#oaDaDaDaD#o.BaDaj.b#5#o##aDaDaDaDaD##aDaD###5.x.x.2.xaDaD#y.2#EaD.2.O.O.OaEaE.9.R#4.XaEaq#E#5aD.B.baD.2aDaDaDajaD#6.xaD#6aDaD#6#6#oaDbQaDaD#6aDaD",
"aDaD.2aDaD.2.2.2aDaDaDaD.2aDaD.2.2#E.2##.R#E#EbTae.s.t.Abu#ia..Fam#G#G.e#G.e.Fa2#i#c#ta4.H.H.Har.H#d#V#3a6#qba#dbr#k#IataRarbe#7#F.ta4ar#d#vaA.C#E#E#E#y#E#E#yb.ap##.R.2#E###E#E.R.R#E#E.R.R.R.R#E#E#6ajaD.xbHajaK.x#5aDajajaD##.x#5#5.x#E#5.x#E.Oaj#5#5.2aDaDaDaQ#2#v.X#v.D.C#y.x.x#y.x#E#y#y#E#EaD.2aDaD.2aD#Eb4bKbc#w#w#v#s.#.i#g.laE#D#s.t#h.X.9.T#D#w.R#E##.R.2.RbS#E#E###EaD.O.R#E.R.RbT.Rb..x#y#yaqbXaAaSaN#S.#.l#yb5#y#4#eaZ.HaO.n.h.N#7.q.da2#9.1#UaBaBaUbo.ebo.Ubd.w.Q.Qbz#parb5b.#E#5#y#E#E#E#E.Rae#F#r#l#GaU#G.eaU#G#G.F#naw#cbLaJaf#V.n.I#7#c#ia0a.#i.JatbsaN.C.x#5.O#y#E#5#5#5.BbV.BajbSaEaea7#DaJaHa1#e#d.9bs.Z#K.SaI#lam.w.w.Fa.bz.ravau.s.saJ.r.ra2#n.yawawbDbW.I.nararar#d#V#daObT.O#5.O#Yaj.lb5#q.pbuac.0aR#0arbTbTbT.9bT#E.X#gaE.T#DaF.t#g#g#s#saE#D#Dbt#H#sbM.9aX.#.Ob5#yaD.OaDaj#5#5aDbS.O#5.O.O.O.O.O##.O#yaD.R.Ob4aEaQbc.D#8.8aq##.R#5aD.O.R#y.O.X#gaEaEbt#8aEaq#E#E##.O##.BbE.B.b##.OaSaQ#sb8.T#8#D.X.R.R#E.R##aD##aD#EaDaD.2#EaD.2.2#wb4aEaNaq.Oaqaq.O.Oaq##aE.#aS.Ob5.x#5.OaD.O###5#5.O#5aD##.x#6.OaD.x#y###E#5###E#5##.x#5##.x#####5###5#6#5.baD#5.OaD###5.O#5#E####.O###5.b##.x#####E##.O#EaD.R##aqb5b5.Ha8.TaG#h#sa8.OaN.kbS.O#5#5aDaDaDaDaDaDaDaDaDaD#6aDaD#6aj#6aj##aD#6aD",
"##aD##aDaD####aD##bSaD##########.RaD.R.R.RbT#g.h.p#Mbu.Q.F.Q..am.F#G.e.ebo#G#U#Ua5awbNaxbx.s#RaZa4.Iaf#7.hau#3.H#q.haV.Wa6ba#taVadaTbZaObM.taL.X#ybSaN.k.C.CaQaN.R#Eap#EaNbcbt#s#w.Ra8#s#D#s#s.M#w.C#zaS.xbH#5.k#z#zaQ.kbSb5bH.xaqaNbc.o.obc#1#z.4.O.x##.O#6.2#EaN.Ta7.zbG.i#R.x#y.x#5aN.o#s#g.XaSbSaD#6#6aD.xaD#z.DaQ#yb5aEaA#v.t.M.9b5.M#h#D.taG.Z.Tbt#4.R#yaq#z#saQ#gaq#E#Eaqaq.Rb5.X#D.z.Zae#s.g#y.O#RaA.#.lbM#v.zb5.Hae#P#PaG.haG.ta1.W#7aP#V#c.1a.#G#GaBaB.U#U.e#G#GaBaB#G.Q#lbL#Varb5#yb5b5bT.Rbpbparba#7a3#9#G#G.e.e.F#G.Q.1#ZbD#XaTaHbr.Zbeaf#t#X#ia.a..Qa2ac.JaA.g.ObS#y#5.R#E#5.B.B.B.B#5bSaqbT.Zaebeae#da8.Hbe#DaH#IbgaI.1am#9aa.1#Z.LbO#q.Z.s.tav.N.db6aaak.yawbn.L.L#p#7.h#p.h.J#t#V#d.H.l#yaj.l#4.H#7bg.r.dbW.I.H.lb5aqb5##aD.R#w#8#D.Xa8b9aF.haG#Dae.9.X#8b0.ta7#gaebF.z.Ob5.ObS.CaQ.8#5bS#E.Oaq##.Rb5###w#g#s.6.X.R.RbTbc#s.8bTaQ#v#waqbS#w#zaNaEaQaE#4aE#8aN.RbTbtbt.8.X.8.R##ajaDaD#6aD###E.8aQ.X#g#8#8#8.X.Rbp#E#E.8#gb4.O#5aD.2.2aD.2.2#6.8aSaE#w.Rb5b5#w#4.X#wb5#5aQ.#.C#E#E.RbSaNaSaq##aq.O.Oaqaqaq.Oaq.O.R.R#4.8aqb5aq#gbc#w.O.R#y#5aqbS#x#w#5#5.O.ObSaq.Oaq.Oaqaq.OaqaqbSbS##.b##.O.b##.O.b.8.O####.O.8#R.M.tbY.p#N#kaF#D#g.M.kbJbSaSaS###6aDb1aDaDaDbQ#6#6bHajaD.xbQ#6.2#6#6bQ#6",
"############aDaDbS##############aDaD#EaD.9bZ#r.S#l#l.Fam#G#G.e#G#G#G#G.e.eaU#U#G.F.ma.a.buazbNbNbD.JbDac.Navau#q.s.P.A.pat.I#pbqbg.rbOarby.P.P#g#P#g.M#v#s#R.MaQ.May#sbt#sbcbtaL.PaX#Pa7.z.P#N.Pa8#wb0aXa8.M.Xae#saEaQ#s#s.MaE#PaEaEaXaQbc#8.6#S#1.O#y.OaD.xaD#E#wa7a6.zbPbF.l.x.laNaeay#s.T#P#Dbcbjaj#6#6.2#6aD#EaN#1aNb5bT#s.z.M.t#sb5.H#F.PaG#h.t.TaebTaE.MaE#g#s.TaQ#gaEaqbT#w.M#vaH.Y#k.t.Z.MaXay.laqaX.zb5bMbF.z.g.zaG#Daea6aHaT#Ca6#jaG#0aR#pbua.#G.FaBaB#W#W.F.e#G#G.F#G#G.Qa.#p.n#0aO.9.Z#F#7aG#7aG#pbna3#W#U#GaU.F#W.F.Qa0a0aJ#q.T#s#g.T.Zb2#Xa0.Q.Q.F.Fa2aI.raHbF.#bc#w.RbT.Xa8.8#5bE#5#5#5#4#waebs.9.9#s.t#g#e.zaF.p.rb6akaka5.Qa..daxb9.H#da6.W.W.c.qb6.Q.Q.1.F.Q.F.Q#lbzbg.r.r.rbL#XbD#7#7.tbxby#0aRbDaIaIa0.Nax.sby.ObJ.O.x.x#5#yb4#8#s#4.9b9aG#FaGa7bTb5.gaua7bFau.z#vae#4.CaQaEaSaQaSaNaEaq#Eb5#4aE#s.Tbt#s#s#s#gaE#4#EaE.TbT.R.T#D.XaE#gaQaQ#w.X.T#D.Ma8#s#g.9bT#s#8ae.X#waEaN##aDaD#E#EaD.R.R.8#g#D#v#S.T.Rb5.9aN#g.gaQ#z.Cb4#zbS#5##aDaD.2#E.Rbt#sb5.R#w#P#g.T#sb5b5.M#s.CbTaNaE.X.XaE#4.XaE.Xaq.X#saN.XaE.X.X.M#gae#s#Dbtbt#s#gaEaq.R.XaQaN.X#w#waE.8b5.8aEbtaE.Xbt#g#w#g#8#zbS.b##aDaj###5.O##aDaD#E#5.8.8#e.P.pbI.p.AaHau.tbFaE.O#ybSay.k#5aDaDaD.B#6.2#6bQ.x#6.2#6#6#6.x#o.xaK.2aj",
"aDaD#E########aD##aD##.OaD##.O.2.2#6#E.Ra7#CbRa2.F#GaUaUbo#G.F#G#G.Qam.F#G.eaU#G.e.F.Qa.a.a..Qa.a0.r.Naz.pavbPbFbxau.A.pataf#cb#.r#u.J#F#qa6braGaG.XbTaX#HaXbsb5ae#S.i#vbX.Xb5.g#H.Y.Pa8bM.s.u.Wa7a7#ha6#s#Cb9.9a8a7ae.9a7#haGaG#Da8aq.XaE.X.8b4aEbS#E##.2#EaD#Ea7bYa6bTa7.za8#y.gaX.Xa8.M.T.T.TaN#5#6#oaj.2aDaD#E.2b4aX#w.l.H#P.t.PauaZ.Hbe#jaW#KaGbrarbT.T#D#w.9ae#sa8.XaG#PaOa8.t.P#C.A.A.h#VaO.TbF.9.l.z#Db5.9aG#Dae.PaGb7arae#C#hbearaGaGb7.n#pa0aI.F.F.F.F.F.F.Qam.F#G.e#G#G.F.Q#c.I.c.tau.Na0bgaIbgbBaIaIaI.F.F#U.F.F.1.1#i.L.h#F.9.R.R.8.8.9b7#K.raI.Q.1a2a2aI#rbO#PaQ.M.Xaqae#h#D#gaq##.O.b.8aN#DaFaF#gaq.X#saE#wb5a8.t#.#ibmawa5a.a..r.A.z.lb5a8#Fa6b2#b.m.Qa..Fam.F.F.Q#l#lbBaIaIa.a.aIaIbg.rbz.Aax.IafbCaIa..mbu.NbP.z#RbS#EaD.x#EaD#yaS#vaE#y.H.t.P#H#D.laO.H.TbPaH#CaA.TbTaN#s#zaNaN#w.9aN#gaE.X.9#s#HaFa7#s.T.X.9a8#D.T.9#g#Dbs.R.T#D.Xae#v#g.Rb5aE#g#gaEbs.T#g.9.9#D#2.T#4.R#g.6#w#5#6#6#5.O#5.RaQ#8aE#4#DbtbT#4#R#s.M.MaXab.X.k#zbS.OaD#######E###s#sb5b5#4aX#v#v#gb5aNbt.XaE.Maeae#g.T#s.X#w#g#s#gaEaF.T#4aE.T#D#h.Ta8#g#2#2#D.X.T#DaE#s#s.M.Xa8aq#w.M#sae#saF.Tae.XaF#v.TaL#S#z##aj###6.x###5.xaD#E.2.O.O#E.Oae.MbZbO.cbYbNaZa8ae#4b5.l.OaN#w#y#5#5aD.xaDaD.x#6#6bQ##aDbQaD#6.2#6.x#6#6",
".x.2.2##b4aQaSb8#v#zaq.Rb5bp.Rar.R#Eb5.Ha6#Kb6#l.F.e#GaU.eaU#G.eamamam.F#G#G#G.F.1#ibC.JbD#cac#f.N.Waua1a7bx#e#4.H.g.P.u.sb7#7.AaJ.taGa7ae.HbT#v#vbTbp.Ta9aH.Tb5bTaX#s#4aX#v.g.Hb9av#I.tb7arb9aH#AaFb9.9a7.t.Z.9beaJ#ja6#F#F.Za7.tbs.Rbt#SaN.R#E#5aDbQ.2#E.2.2#E.TaGb7aOa6.t#4bv#ebF.gbsb9.Tbrbsaeb4#5#EaDaD.x.2aD.x.Rbcbt#4b.ae.u#AaH.z#0aOa8aG#H.t#e.9ar.z.zaO#d.h.Nb2#q.hbraR#qbO.I#FbL.rbU#qara1.t.g.H.T.t.9aOaG.tar.t#Caearae#Cbr#0b7#p#r#p.J#i#l.Qam.e.eaU.F.F.F.Q#Gam#G.F.FamamaYao.dbzbzbza.a.a.#la.a.#l.1.1.1.1.m.1a.a0.L.n.s#q#d#y#E##.R.R.RaeaG#FbO#7.J#r#Cbrb5#yb5#y#EbT.X#g#g.X.Raq.8aSaS#wb4b8bc.X##.R#E.R###y#y#wa7#F.LbNbLad#u.W.V#db5ara6#Fbaaf.J#i.1.1.1.1.1#9#9a5a5.G#Z.dbnbn#c#TbnbDbDbDbn.qaYb6.FaI#i#..Nauay.C#5.xbH.xaD.x#E.xaEbXa8aOaZ.hbIaH.Tbear.n#C#kaHaGbs.H#s.#.Cb5.MaF#gbTae#D.Za8#Da9#Dbs.T#Cbr.9.9.T#D.9a7#Da8bTa7#D.X.9bt.T.RbT.T#s.H.9ae#Da7.9a8#8a9#va8bT#w.TaQaD#5.2#####E.O.6bt.R.Rbtbtaq#w#s#s.HaE#Pbc.XaN#z.8#####EaDaDaDaq#s#sbT.Rb5#gaFaL#s#w.g.Xaqab#sbT.R#sb0#haEbT#d.T#D.X#s#sa8.R#s#H#ha6#d.9.Ta9#H#D#D.gae#S.TaqbTaE#Dbs.9.T.t.T#v.g.RbT.T#8.M#s.XaDaD#Y#6#5##aDaDaD#E.b##aD#5#E.O.ObM.Hbs#eb9.t#gb5.lb5.l.9#e.gbTb5.R.Oaq#5.O.O#5##.O.OaSaNbS#5aD#6aDaDaD#6",
"##aD#E##aE.6bt#8#8aQ#w#4.Xa6#F.V.VbObWax.L.Ga.#l#l#G#G#G#G#U.e#G#G.Q#Gam#Gam.F#Z#Xax#qa4.sa6#D#j.t#g#s#s.C#y#y.l.O.lbX.t.9bT#3#h#Daq#y#y.Ob5b5.##DbT.Rbt#A#2.Tb5bTbtaQ#Ea8#v#v#d.9.za9#k.t#d.9#D#H#g.R#y#g.T#dar.9#j#HaH#I#h.Za6.Tbs.Rbt#v.8.x.x.2.2bH.2bQ.2#E.2#s#D#daO.M.t#d#ybT.tb0.t.z.zb9.9.M.Db4aD#6.2#6aD.2.2#E#w.6#g#y.lb9.WaH#7.Zb5bva8.PbFbTaObM#D#D.HaR#7#M#r.NbL#t.c.J#7#V#t#M.rbuat#0.z.ubraZ.PaG#d.HaG#F.H.t.Pa4.9be#Kbrarba.J.r.7a0a2.QamaB.yak#U#G.F.Q#G.F#G#G#G#G.F.F.1aa.m.F.Q.1#Waaaa#9aa#ia5bCawbCawbn#c#cbn#3#d.n.Mae.R.R.R##.2aD#EaD#E#Eb5.8aN.XbS#y#y.x#E.x.2.2#E.2.2#E#E##.8aD##.2.2###E.2aD.2.2aDaD#E#E#E.Rar.9.Ta9#2b9.lbvar.Z#jb2aRbaa#bm#i#9.1.1.1#9a5aaa5#n#n.d#c.L#cbD.L#cbD#T.ya5.1aI.m#iac.h.Va8#y#EaDaD#6.xaj#5.x.xaqbt#s.H.HaeaG#k#I#F#dbT#g.PaA.MbT#4.TaX#waq#g.P#C#D.Tbr.gb2.Tbr.Zbr#jaH.T.9#d#D.t.9#s#D#dbT#s.T#d.9bt#D#4b5#s#sb5b5.g#s.M.RbT#D#2#Da8b5.9.T.o##aD.2#5#E.x##bc.6aq#ybc#sb5bM#e.Ma7bF#PaE.l#w#1aQ.OaD###6#EaD##aQaQbT.RaqaE#saQ#gbS#E#E#EaQbc.Rb5.T#v.t.T.RbTbt#sbTa8#s.MbTa8.T#haGae.9a8#D#h#vaebT#w#DbcaqbT.T#H#j.Ta7#gae.t.ZbTaq#s#saqb5.O###Y#Yb1##########aDaDaDajaD##.O#5b5.Ca8aZ#g#8ay.Cb5bT#0b9#Fa6a8a8.gaEbcbcaQaQaE#w.8#w#gb8.8aDaDaD#5aDaDaD",
"#6bSb1#E##aS#gb8#s#w.9#gaG#kah#LaIa.a..Q.Q.Q.F.F#G#G#G.e..#G.F#G#U.1.F...eam.1.G.L.saZby.C#waeaE.X#w#waN.8#5#y#5#y#y.##v.HbT#daGaL.CbH#y#y.x#yaEbt.g.R.Xbt.T.M#g#w.XbJ.xb5.X#v.M#w#D#v.t#hae#w#D.Maq#y#E#4.T#s.9bT.ZaG#Ha9#hbsae.Ta8bTaE#8.o.O.E.x.xbQ.2.2.x.2#EbcaFaeb5a8#Da7bTae#P#s#D#D.t.zaE#s#1aN#EaDaDaDaDaDaD###EaSbt.g#4b9bY#F.Tau.gbTaebt.gbTb5aO.tbY#3b7#q#7bLaM.p.V#paV.V.n.c.N#M.raub7bZaW.P.M.W.t.H#daG.ub9.z.ha7b7a6.uaG.Z#FaV#r#pbn#Za..F#9ak#n#U#G#Gam.F.F#G.e.F.e.FaU#G.F#G.F.F.F#W.waaaaaa.w#9aYawbCbCawbC#T.LbNau.s#e#s.X.O.R.2aD.2.2aD#E.2.x.xbQ#E#6.2aD#E.2.2.2.x.2.2.2#E#6#E.2.2.2.2.2aD.2aD.2.2#E##.2##.2#E.Rb.b.#4#gaE#4bTb..R#F.hbraG.J#ba5.m.m.1.F.F#W.F.F.1.F.1.Q.ma..Qa.#l.Q.F.1.1.F.F.m.Gac.Va4.Hb5#yaD#Eaj.x#5##.x#5.x#yaNbX.M#d.9a7bYaGaG#s.9.9.t#va8bTb5.Mbt#Rb5a8a7b0#Hau#Pae.t.T#d#da7bYaFae.9.9a7aL#s#s#v.XbT#g#Sae.R#Dbc.9bTaEbt.gb5.H.MaEb.bTbt#2aFae.Raq#vbc##aD#6###5#EaDbc#1.O.RaQ#SaE.CaEb9.MaXaAaFaQaqaE#zbS##aDaDaD##aq#saQaqbT.8bc#g#E.O#E.2#y.OaEb8.8b5aE.TaFbtbT.X#8.MaqbTaEbtaEaq#d.taH#Dae.H.X#v.TbTaq#w#8.6aqaqaeaF#C#D.Taeae#8#gaqa8.6bc.O.O.O#5#Y#YaDaD##aD####aD.BajaD#5#5.O.O.xaq#w.Mb0bk.k.b.Ob5.n#K.p.h.t#ea8aE#s#s#zaQb4.8aE#gaN.8#E#E.2#6aD#6bE#6",
"aD.baDaD####bSaeb8#g#ga7aG#M#L#L#lamam#G...e#G#G#G.e..#G#G#G.F#G.F#UaU#G#G#G.F.G#t#d.lbM#yb5.Rb..R.R#Eb5.O#5#5#5#y#5aN#v#s#g#s.T#sbJ.x#E.x#O.x#yaNaNb5#w.TaEae#g#4#y#y.x#y.x#wbc#s#sa8.RaE#s#s.M.O.x.x.x#E.X#g.X.Z#s.Xaeae.9#E#w#sbc#s#waEb8##aK#6.2bE.xbH#6.x.x.8aQaXbcaeaE.gb5aEbt.M#s#sbcbcaEaQ.C.xaDaDaD##aDaD##aD.2.Obt#S#8.t.TbeaZaF.PbX#vaQ.Xay#s.Mb0.Y.P#j.h.haJ.p.Wa1a1bP.u.h.P.p.p.p.p.PaAaF#Pae.t#H.tbF#D#Db9.gaL.u.taGbYaGbebZ#C#XbN.J#iaI.Q.Kamam.Q.Fam#G.F#U#G#G#U.FaU.F#G#U.F.e.F.F.F.F.F#U.1.F.F.Q.1a..1a0a.a.a0aM#NaF#s#8aE.R##.2#6.2.2aD#6#6#E#6.xaD.x.x.x.xbQ.x.2.2.2.EbQ.2.2#6.2.2.2.2.2##.2aD#E.2.2aDaD###E.2#E###E.x.xap.R.Rb.bT#v.t#DaT.j.r.r.1.Q.F#G.F.F.F#U.F.F.F.F.F.F.Qam#G#G.F#G.F.Faa#Tao#q#V.Hb5#y#y.x#EaDaD#5ajaj#yaj#E#yaQaF#g#g.t.M#d#saF.zbtbt#g#4b5.x.CaN#zaQ#waybGaF.Maea8#e#v.z#w#g#ab0.Ta7#sbtbtaE.X#8#g#w#8#vaN.O#gbcaNaNaNaEaN#E#yaE#s#w.X#8#v#vaQ.X.Mbc.kaDaDaj##aDaD#Eb4bcaSaNbt.DaE#w#saX.g#4aE#v#v#zaN.8####aD#o##aDbSaQbc.8.Raq.6#1.R##.R#E#y##.8aSaEaE.8#w#s#8aQ#gaE.8aq##aqaQbXbtbc#s#g#D#vbt#s#g.g.Ob5.8#zbc#zaS#w#DaL#sae.X.X#8bc#waN#v#1#yaqbSaDaDaDb1####aDaD###Y#6bEbJ.O#y#y.O#y.C.X.M.#ab.4#5#5.la1bIaMaMbIa1.R.Raq#y#E.x.RaSbtb4aD#E.2#6.2#6aD#6.2#6",
"bj#Y.B####.R####.RaN#g#g#j#I#LbgbB.e#G.e#G#GaU.w.w#G#G#G.F.F#Gam#G#GaU.e#G.Fa5.L#V#0.l#y#y#yaD.x#E#E.x##.k.4#Eaj.x.Ob5aN.M#g.Maq#y.x.E.x.x.x#E.x#O#y#y#wbc.Xaq#E#O.x.x.x.xap.xaSaS###Eap.R#w#w.R.x.x#5aDbH.2.xaqaE#g.8.2.R#E.x##.OaN#g.O.x#5aD.x#6#6#6.x.2.2.x.2.x#y.k#saSbS.O.xb5aN#z.oaQ#z.MbJ.x#5#yaD##aD#6aD###6###E#E#wbcbc.Xb5b5aO#wbtbcay#R.C.k.M#saF#2a9aWa9#H.t.t.zae#R.g.z.tbF.t#sb9.T.z#gaq#yaq#R#saX#s#wb5b5b5aebcaX#saea8aO.9aZbZ.h.h.J#Mbgbza..K.Qa..F.F.F.F#W.F.F#G.F.F.F.F.F.F.F.F.F.F#G.F.1.1a2.maIaIaIa0#ibLbn.Wav#PaNaEaq###E.2.2#6.2aD.2.xaD.x#6aD.x#6#6#6.x.xbQ.x.2.E.2.2.2#6#6.x#6#6#EaD.2aDaD.2.2##aDaDaD.2aD.R.2.2#E.2#E#y#E.RaEaE#Pb0#haG.J.Ga0aIbB.Q.F.Fa2a2.F.F.F.Q.F.F#G#G#GaU.F.F.1aabnaxax.s.H.l.x#y.x#y#5.x.x.x.x.x#5#5.xaqaQ#s#saEbT.R.8.M#8bt#w#E#y.x#E#5#5#w#z.C.CaQaN.O#y.xb5aEaQ#w#wbcbcbcaEaEaN.O#E#yaN#w.8b8aSaD.O.8b4#wb4#xbSb5#y#EbSaN.C#waE.8aNaNaN.M.C###5#6.xaD###5aD##aSaNb4#z.8.O.R#waQ#wb5aq#wb4aSbSaD#E##aD##aDaDaD.8.XaS#w.8aNaS.O##.R#E#E#E#E##b4aEbS.O.O.kaE.C#5#y.O.O#5.C#z.o#1#w.O.gaQ#sb8.C.O##.O.O.R.8#z#x##aEbc.X##.R.RaEb4.8.4b8b4aD#5.O#5#6.BbS.baD##aD.2aDaDaj.Ob5b5.l.lb5a8aZ.9.HbJaj#y.lbybPbz.ra..rbP#g.X.O#E.2b4#xaSaS.2aD#EbQaD#6bQaD#6.x#6",
"#Y.b#6#6#6aD.R#E##.R#E.X.T#FaJ.SbBam#lam.F#l..#Wak.w#G.F#Gam.Q#G#GaUaU.e.eam#n.0aR.H#y#yajbH#y.x.2#5#E.xaS.k.Oaj#y.x.x#y#y#O#y#E#O.x.x#y#y#E#Oap.x#E.2#y#y.xb5.R.x.x.x.x.xaj.x.x.x.x.2#y###EaD#6.x.B.BajaD#y.x#E.2.2#E#EaDaD#5###E#E.2.2#E#6bH#6aj#6#6#6.x#6.2.xaD.x.x#6#5#5#5.xbHaD#5.xaD.xaDaj.xaD.2#6###6.2#6aD#6aDaD#E.x.xb5#y#ybp.x#y#y.x.x.x.x.x#E#y#w#gaQ#s.M#R.C#w.C#y#yb5b5#y#Eb5#y#y#E#y#Oap#yb5.x#E#y.x#O.xapb.#Eb.#y#E.R#yb.b5b5.9#d#dbebZ#F#j.WazaV.G#i#i.maIa2aI.F#l.F.Qama2aIaIa.aIb6a2aIa0bR#b#cbD#X#r#.#rbDb2aP.gaE#w#y.R###E##aD#6##.2aD.2.2aD#5aDaD#6.x#6aj#oajbQ.x#6bQbH#6#6#6.x#6aD.2#6aDaD.2##aD.2aD##.2aDaD#6aD#6aDaD#6aDaD#6#y#Eaq.XaNbT.9#V.h#k.JbD#X#bbRb6a2a2#l#l#l#l#l.F#G.F.F#U.F.1.1a0bubPbO#e.O#y.O#y#E.x.E#EaD.xaj#E.x.x.R#E.8aq#EaD#y.x.R###5#5.xaD.xaD.O.x#5.xbH.x#y.x.xb5.x#E#5.x#5###E#y##.x.x#E#E.xbQ.x#6#5##aD.2##aDaD#6bQ#EaDbH#6#y.x#y##.x#y#E#E###E#E#y#EaDaDaDaD######aDaD.OaD#5aD#5###5#E###E#5.RaD#E##aDaD##aDaDaDaD#EaD#E.8.8bS#E#EaD#E#EaD#6#EaD#5###5#5aD.OaDaj#6aD##.baD#5###Y####.O.O.O#y#5###E#E#E#E#5aDaDaD##aD#E.2#E#EaD#EaD.x#yaD.O#y.x.x.xaD#5aDaD#EaD#EaD.B.BaD#5.C#g.T.z.zbrbZ#7#Faebv.x#y#ybx#ubz.1a.a..A#2#saqaSaSaSb4#E##.R.2aDaD#6#6#oaD#6aD#6",
"#Y.B.B#6#E.2.2.2.2.2aq#Eb..Rbe#F#K#b.7.SaIbBbBa2a3#n.Famamam#G.F#G.e.e#G.Fa2.G#7#V#d#4.CbS.bbS.x#E#5.2.O#5aj.b##aj#5#EaD.x#y.R#E#y#E.x#5.O.x.x.x.x.x.x#E#y.x#5#E#6aj.x#6aDaDaD#6.x#6#5aDaD#6#5aD#6.BaD.B#5#Y#6aD#E#6aD#6#6ajaDaD#6#6.x.x#5.B.fbEbEbE#6aj.2.x.x.2#5.2b3#6aD.x#6#6#6ajaj#6bH#6bH#6aD#6.x#6#6#6#Y#o.2#oaDbQaD#E.x#E#E.x#E.x.2.2.E.E.x.x.xapbH.xb.#E.R#y#y.x.x#5#E.xaj#5.x#E.x.x#y#E.x#y#E.x#y#E.x#E.x#E#E.x.x#E#y.xbH#E#E.x#y#y#y.R#y.R.9.9bsbebe#e#q.cat#7.NbLbU#X.J.J#faV.JbNbN#7ax.JaJ.p.J#7a6.n#d#db9a6b9b7arb..R.O#E#E#EaD##aD#6##aD#6##.2.2#E#6.xaj.xbE#6bQ.x#6bE#6bQaKbHbE.2#6aD.2#6.2.2#6.2.2aDaD#6#####6aD#6aD#Y#6#6#o.2#6ajaDaDbHaj.O#E#Eb5#4ae#g#daOb7b2.JaV#r#Kbn#p#pbnbDbb#bbRb6.ma0a.bz.rbubPaubF.MayaNay#zaN.O#yaD#EaD.x.x#6#E##.O#E#EaD###5##.x.x.x.x#5aD.x#5.x.x#5ajajaj.x.x.B#5aj.xaD.xaD####aD#5#6.x###5bHaDaD.xaDaDaD##aD#6##aD#6aDaD#6aDaDaD#5#yaDaD#5#EbH#E##aD##aD.2######.baDaDaDaD####aD#EaD#EaD#EaD###E####aDaD##aD.2aDaD.2aD#E.2#E.2aD#EaD.x.xaD.x.2#E.x.xaD##.x#6aD.x#6aDaD.b##.B#5.b.B#5#5.x#5##aD#5aD.xaD.xaDbS##.2.2aD#E.2###5.2##.O.x##.O.x#6.O.xaD.O#EaD#5###E#6aDaD.Baj.O.X.P#A#I#M#Mb#.Sb##F.9b..l.H#F.ra..1.m.m.W.P.6#wb4#xaDaD########aDaD#Y#o#oaDaD#5b1",
".B.B#oaDaDaD##.2.2######.Rbp.R.9.9.X#D#D#F#j#p#X#Xa3aI.Qamam#G#G#G#G#G.Fa2aI.rbL.tayaN.CbJ.CbS.xaD.O###5##.b.b.O.b.4.k#x.8.8aS.8.Oaq.ObS.C.O.O.O.O.O#5.O##aDaD.x.xaD#6aD##aD#EaD#6aD#5.2aDaDaD#6#6.B#YaD#6#6.xaD#6#6#6#6.B#Y#o#o.BbH#5aj#6#Yajb3#6bE#6.B#6.2#6#E#6#6aDajbE#YaDaKaD#obE#6#6#6#o#obH#6aDaD#6#o#6#o#obQ#6aD.x.x.xaD.x.x.2.x.x.xbQaj#6#6.x.2ap#E#E.x####aD##aDaD#5aD#6aDaDaD#5#5aD#E#E#EaDaD#6.x#E#5.x#E#5.x#E#5aD#E.x.xaj#5###E.O.8#y.R.R#yb5.R.R.Rb5bTbM#db9.T.t.tbr.t.PaA.s#d.H.l.9#4.gb9.g#d.lb.b..xb.#E.x#E#E.x#E##.x.2#6.2aDaD.2#6#6.2aDaD.2aD.2bQbE#6bQ#6bQbE#6#6#6#6b3.2bE#6bQ.2bQ.x.2bQaD.2#6.2#6#####6#6###6aD#o#6aD#obA#o.B#oaD#6bQ#E#5.x#5#5.x#5#y.xb5#wae#sa6#d.9#d.9#db7ae#q.h.N.p#.#..NbN.haubO#P.sayay.M.#bcaSbJbSbS.b.baD##bS##########.O######.xaD#5#EaD#5aDaDaD#5aj#5.Oaj#5aj#6aD#5ajaD##.b##aD#5aDajaD###6#6aD#o###YaDaD#YaD#YaDaD#5.b#5#6ajaDaDaD#5aD.xaD.x#6aD#6aDaD#6aDaDaD##aD.2aDaDaDaDaDaDaDaDaD.2.2##aDaD##.2.2##.2#6aD.2aDaD.2aDaDbQ#EaD.2aD#5.2.xaD.x#6aD#6#6aDaD.x.BaDaj#Y.baD#YaD.BaDaD#6aDaD#E###5aDaD###E####aD##aD#E##aD#5##aD#E#5#######5#E#5#E#5#y#5###y##aD.B#5#Yaj#5.O.O#g.t#7bUbgbgaI.S#ra7bTaq#4aG.SaI#l.mac#q.Xb4#wb1aD##aDaD######aD#6#o#Y#oaDaDaDaD",
".b#5#oaD####aDaDaD#6aDaD###E.R.R.R.R.xb5.Hb5.9#7#pbnaI.F.F.F.F#G.F.F.F.F#f.J.h.PaG#Dbt.##1#z.k.C##.OaD#6#5.b.b.b.4#x.4aS.4.C.8.C.O.O.O.ObS##.O#5#####5####aj#E#6.x#5aD.2aD#5aDaDaD.2.2aDaD#6aDaDbE#6#o#6aD#6bQ#6aD.2aDaD#o.B.B#o.B.B#6#6bEaj#6.B.B#6aDaDbHaDaD#E#6bEb3#o#oaD#Y#6.B#6#6aD.B#oaD#6aDaD#6#ob1#6#oaD#6#6aD#6aDaD.x#5.x#6#6#6aD#obE#6#o#6#6.2bQaD###E###E#6aD###oaDaDaD#Y#5aDaDaDaDaDaDaDajaD###6aDaD.2aDaDbQaD###6#6#6#6.B##.b#6#5##aDaD###EaD#E#E##.R#E#yb5aqaq#w.gaEaE#gaE.C#y#E.x#E.x.x.x.EbH.xbH.x.x.E.x.x.EaK.x.x.x.x.2#6#6#6aD#6#6#6.2#6.2.2.2#6#6#6aKb3.2aKaD#6aK#6#6aK.2b3.EbEbQ.E#6bQbQ#6aD.2aD##aD#####6aD#6#6b1#o#6#Y#o#oaDbE#6aDaDaD#E#6aD#5.B#5#5#6.x#E#5.R#E#E.O.R.Oaq.R.C#w.X.M#P#ebx.s.Hby#0.H#dbTbT#4aqaq.CbJ.8bS.b.4.8b1.bbjb1bSb1##.b##aD###5aD####aD.x#5#y#E#5#5.2#5bj#6aj#5#6#5aD#6aDaDaDaD.2#6aDaD.xaDaD.x#6#6aD#6aDb1aDb1aD#o#oaD#o.B#o#6aDaD#6##b1bH#6#5bQ.2aD#E#6.2aD#oaDaDaDaDaDaDaD#o#6aDaD#6####aD####.2aDaDaD####aDaD######aD#######5########.O.b##bS.4.b.8.4b1bS.4bj.4.4.4.4.4#xbj.4.4#x#xb4b4#xb4b4b4b8#zb4b8#zb4.6#1#z.ob8b4#1#1b8b4b4.CaS#zb4aEb8#1b8.6.6#zaSaS.baD.b#5aj#5.xaO.9#d#q#7.d#M#r#j#gaqbS.8.T#h#7#p#7#3#d.R#E#####6aD#6.2##aD.2.2#6#o#o#o#6.2aj#6",
".b#5aD######aDaD#obV#6#6aD##.R#E#y#y#O#yb5.HbZaz#p.qb6aI.F.F#Uaaakaab6#i#paP#d#d#waNaQ.6bc#z.kbS##aDbH#6aDbHajaj#6#5.xbH.xaD.x.2#5.2.E.xaDbHaD#6bH#6.xbH#6#6bHbQbH.2.2.2.2.2.2#E.2aD#6bQ#6aD#6aDaD#6aD#6#6aDaD.x#6#6#6#o#6#obV.B.BaK#6#6aK.B#obE#6bEbH#o#6aD.2#6aD#6bQaDaDaD#6#oaDaDaD#oaD#6aD#oaDaD#o.2aDb1aD#o#6#6aDaD#6.xajaD#6#6#o#6#o#6#6#o#6#6bQ#6#6.2.2aD.2#6#6aDaDb1aD#o#oaD#Y#YaD#6aDaD#6.B#6#6aD#6bE.x#6#6#6#6#6#6aj#6bEbE#obE#6#6bEaDaD#6aD#6aDaDaD.2#6aD#6aDaD.x.xaD#E.2.x.x.2.2bHbH#6.xbHbHbHaKbHbHaKbE#6bEbEbEaKaK#6#6#6aD.2.2#6#o.2#6###6.2aD.2aDaDbQ#6#6bQ#obEbQ#6b3bE#6#6#6.2#6#6#6bEbQbE.2aDaDaDaDaDaDb1###6aDaDaD###oaDaD#oaD#Y#6#oaD.xaDaD#E.B.B.B#Y.B#6#6aD#oaDaD#6aD#5#6aD.B#5#5.x#5#y#y.l.lbvb5.lb5.R.R#E#y#y.x#y#E.x#5#5##b1aD##aDaDb1aDaDaD#6#5aD.2.x#6.2.xaD.2aD.2.2.x.xaD#5.x#6aDajaDaD#6#EaDaDaD#6.2.2.xaDaD.2aDaD.2#6#6aDaDb1aDaDaD#oaD#o#6.BaD#o#6#o#o#6aDaD#6#o#6.2#o#6.2aD##aDaDb1aDb1#YaDaD#o#Yb1####b1##b1##aD##aDaDb1aD#6aD##aD####aD.baD##.b#5.bbS.b.4bS.bbS.O.bbjbS#x.4.8.4.4bjbj#x#x#xbjbj#x#x#xb4#xb4#zb4#z#z#zb8b8b4b8b8#z#z#z#z.ob8#zb4.8.4#waSb4#z#zbcb8#1#1aQb4.4.baD.B#5#5.C#sa7.s#VaR#0#3bW#3.n.H.x#5bS#w.9ar.R.9.9#E.R.2aDaD#6#6.2aDaD.2aD.2aK#o#o#6#6#6bQ#6",
"aDaD#E.x#EaDaD.2aD#6.3aK#6#6#E#Eb.b5.H.MbO.W#Mbubnal.m.F.F.Fa2.w#n#ibL#7#daO.lb.#y#E#O.R#yap.x.x.2aj#6.2bQ.x#6.x#6aj.xaD.xbH#5.x.x#5#E.2#5aDbH.x#6#6.x#6aj.x#o#6.E#E#EbQ.2.2.2.2.2.2.2.2aDaD.2aDaDaDaD#6#6aD#6aDaD.2aD#o#6#o#6#6.BaD#5.BbE#6#6#6aDbE#6aD#6#6#6.2aD#6#6aD#Y#oaDaD#6#6#o#6#6#o#6#6#6aD#6bQ#oaD#6#6#6#6#6#o#6bHbE#6bE#6#o#6bEbVb3#6bEbQb3.2bQ.2.2.2#6.2aDaDaDaD#o#6#6#oaD#6#6#6.2.2#6.2bE#6#6#6#6b3bQbH#6.x#6.BbQbEaKaKb3bE#6bEb3aDaD#o#o#6#o#obQ#6#6#6aD#E.2aD#E#E.2.x.2#E.2.2bQbQ.x#6#6#6bEbQ#6bEbQ#6bE#o#6b3#6bE#6#YaD#6#o#6#o#6#6#6aD##aD#6.2##aDaD#o#6#6#6b3.2#6#6#6#o#6#6#6#6#6#6bQ#6#6#6aDaDaD##aD#6aDaDaD##aDaD##aD#oaDaD#oaDaD#6aDaD#E.2.2#6aDaD#YaD#6#6#6ajaDaD#6.B.BbE#o#6#o.B#6aj#5bH#y#y.x.x.x.x#E#E.2.2.x.x.x.xaD#5aDaDaD#6aD#o#6#####6.2aD#E.2.x.2.2.xaD#E#E#EbQ.x.2bH#6aD.x#6aD.2aDaD.2aDaD.2aD.2.2aD#E#6#E.2aDaD#E#6aD.2aD#####o#6#6#o#6#o#6.BaD#o#oaj#6#6#6#6#6aD#6aDaD.2aDaD##b1#o###YaDb1b1#ob1###o##b1#o##aD#6#oaD.2###o#6aD#6#6aD.B#6aj#6#6#6#6aDaD.x#6#6bQ#6.2aDaD.2####aDaDaDaDaDaD#YaD#oaDaDaDaDaD#6#6aD#6aDaD.2.2#E.2###E.2aDaDbQ.2##.2.2.2#E.2.2#E#E.2#E#EaD#EaD#E#E#6#5aD#6.b.4ay#s#F#Fauaxax.haxbOby#y#ybJaN.X.RbT.R#E.R###EaDaD#6aDaDaD####.2aDaD#6#Y#YaDajaDaD",
".8#5.2####.2###EbA#6aDaKbH.x#EbTa6.V.J.G.raIaIb6#Tal#9a2.F.F.F.1a.a.aV#qbMbv#y#y.x#E#E#E.R#E#E#OaDaDbQ#YaD#6aD.BajaDajaD#6aj###E.2aD#6.xaDaDbQ#6bQaj#6#6aD#6#6#6.2aDaD#E.2#6#EaD.2.2.2.2aD.2aDaDaDaDaD.2#E.2.2aDaDaD.b###6aD#6bH#6aD.Baj#6bE#6#o#6#6aD#6bAaDaD#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6bA#6#6.2aD#o.5#6aDaKbQbE.E#6#6b3#ob3b3bQbQbQb3#6#6bQbAbQ#6aD#6.2.2aD#6#6#6#6#6#6#6aDaD.5#6.2bQ#6#6bQ#6#6bQ#6#6bQ#oaD#6#6#6#6aKaKbEbQ#o#o#6#YbV#6#o#Yb1#o#o#6#6.2aD#6#####EaD#E.2#EaD.2.2.2bQ#6#6aD#6.2#6#6.2#6#6bQ.2#6bQ.2#6#6#oaD#6aDaD#o##aD#oaDaD#6#6.2aD##aD#6#6#oaD.2b3#6bQ#6#obQ#6#obQ#6#6bQaDaD.2aDaD.2aDaD.5#6#6.2aDaD.2##aD.2aD#oaDaD#o#6aDaD#6.2.2.2aDaD#EaDaD.x.2aDaDaK.x#6#6aj#6bA#6#6bHaD#5bH#6aj.EbH#6.5#obV#6#6.x.x#Eaj.xaDaDaDaDaDaDaD###oaD##.2.2##aD.2aDaD.2####.2aD#E.x.2.2.2aDaD.x.x.2.2##aD.2aD####.2aD###6#EaDaD#EaDaDaDaD.2aDaD#####o#6#o#6.BaD#oaDaD#6#o#6bQ#6.x#6#6aD#6#6#6aDaD#oaDaD#oaDaDb1aD#o###Y#6#YaD#6#YaD#6#6aD#oaD##.2#6aD#6b1ajbQ#6#6aK.2aD.xbQ#6bE.E.x.x.2###E.2aDbSaDaD.2.2aDaD.2aDaDaD.2aD#E##aD#EaD#E.2aD#E.2aD#E#E######.2#EaD#E##.R#E#####E.R###E.RaD#E##aD#E#5aDaD#5#6#5.O.Ob5#g.WaTad.K.Ka.bu.ha4byb9b0#C#D.Za8##.R######aDb1#Y#6#E.8###E.R.O#6#5aD#6aDaDaD",
".ObSbSaq#E#E##.RaDaD.Ob4aQbt#vaG#raI#l#la2b6.Qamaa#n#9b6.1.F.F.1aI.r#u.t#d.x.x#E.xaDaD##.R#E#E.2.2aD#6#oaD#6aD#6.2aDaD.x.x#6#5#6.x.2bQ.2#6bH.2bQ.EbE.2aK#6ajbQbQbQ.2aD.2.2bQ.2.2bQ.2.2bQ.2.2.2aDaD.2##aD.5.2aD.2aDaD.2aD.2.2.EbQbHaK#6#6.E#6#6aK#6.2bEaD#6#6#6.2#o#6.2#6aD#6.2#6.2#6.2#6.2#6#6#6#6aD#6.2#6#o#6#6#6#6#6aD#6bQ#6#o#6#6aD#6#6#6b3.2bQbQ#6#6bE#6#6#6.2#6.2aDaD#o###o#6#oaDaDaDaD.2.2.2#6.2bE#6#6#6#6.xbE#6aD#6#6#6#6bQbEbQb3#6#6bVaD#o#6#o#o#oaD#o#o#6#6.2.2.2.R#6#E#E.2.R.2.2.2.2.5.2aD.2.2aDbH.2.2.2.2.2.2.2#E.2bQ.2#6#6#6#6#6aD#o.2#6#6.2#6aD.2aD#6#6aD#6bQaD#6bQ#6aD#6#6#6.2#6#6#6#6#6#6#6#6#6.2#6.2.2#6aD#6#6#6.2.2.2aD##aDaDaDaD#6#6#6.2#6aD.2#E.2#E###E#EaD#E.2aD#EbQ#6#E.x.x.x.2.2.2#EaDaDaD#6bE#6bVbV#o#obV#Y.BaD#5.BaDaD#6##b1aDaD###6aDaD#6.2aDaD#EaDaD#EaDaD###EaD#E.2aD.xaD#5.2.xaD.2.2aDaD##aD.2aDaD.2aDaD.2aD.2aDaDaD##.2#6aDaD#6##aD#6aD#o#6#6aD#6#6aD.x#6#5aD.2aDaDbQaDaDbQaDaD#6#oaD#6##aD#oaDaD#oaD#o#6#6aDaD#6#6aD#6.2#oaD#6.2#6aDaD#6#6#6bQ#6#6.xaDaD.2.2aD.2aDaDaDaDaD####aD.2aD.2.2aD####aDaD####aDaD#EaD##aD####aD####aD##aD########.R######aD####.R#####E####aDaD######.O####aD#5.Ob5b5.MaFau#.bz.Gaw#ia.ac.J.p.r#LaM#k.T.X#zb4.8##.baD#6.2aDaD#E#E#E.x#EaDbHaD#6bE#6",
".O#xb8#1bc#8.6#g#waqaq#g.u#BaT#MaI#lamam#G.F#G#G.Fa2a2#W.1.1.Q.1.ma.#ubN#R#y.xbQ#6.2bQ##.2bQ.x.2aKaD#6aK#6#6.2bQ.2bQ.x#6bQbQaj.2aKbQbQ.E.x.2bQaK.2bQ.E#6.x.E#6.2.5#6aD.5#6#6bQ#6.2.E.2#6aD#6.2.2bQaDaD#6aD#6.5#6.2bQ#6.2bQ.2#6bQ#6ajbH.fbH#6#6#6#6#6.2#6aD#6#6#6aD#6#6#6#6#6aD#o#6#6#6#6#6#6#6#6#6aD#6#6aDaDaDaD#6#6aD#6#6#6#6aD#6#6#6.2.2#6.2b3bQ#6#6b3.2b3#6#6#6.2.2#6aDaDaD#o#6aDaD#oaDaD#6#6#6.2bQ#6#6bQ.x#6aK.2aD.x#6#6bQbQ#6#6#6.2.2#6#6#o#oaD###6#6#o#6#6#6aD.2.2.2#6#E#E#E.2.2#E.2.2.5bQ.2.2.x.2bQbQ.2.2#E.2bQ.2.2bQ.2.2.2aD#6#6#6#6.2.2aD#6.2#6#6bQbQ#6aD#6aD#6aD#6#6aDaD.2aDaD.2#6aD.E#6#6aKaD#6bQ#6#6bQaD#obAaDaD#6aD##.2aDaD.2aD#o#ob1aD#6aDaD#6.2bQ.2.2.2aD####aD#EaDaDaD.2#E.2.2aD#E.2#E.2.2aD.2.x#6#6aKbE.BbVbVbV#o#6.BaDaDajaD#6aD###6#####6####.2.2aD.2aDaD.2.2aDaD.2aD#6.2#6.x.2#5aD.E.2#6.2.2aD.2aDaD.2aDaD.2aD.2aD#6.2.2aDaDaDaDaD#6#oaD#o#oaD#6#6aDaD.xaDaDaDaDaD.2#EaD#E#E#6#6#6#6aD#6aDaD#6aDaDaDb1aD#o##aD#6aD#obQ#6#6bQ#6aD#6aDaD#6.2aD#ob1aD#6aD.B#6aD#6aDaD.2aD#EaD#EaD#####EaD##.2####.2.2aD#ob1aD#o##aDaD#6#6#6aDaDaD##aDaDb1aDaDaD.2#####EaD##.2##aD####aDaDaD.2aDaDaDaD#EaD.RaD#EaD.xaj#5.x.Oay.g#d.V.G#nak.w.Q.Qa..Q#l#lbR#Ka6aeaQaNaD##aDaD#xb8b8bcaQaQ#saQ#1#1.8bE.2#6#6",
".8.4#z.Dbk.i#8#gaq.9.X.T#kaM.Sbg#l.F#G.F#l#Gam.Fa2.F.F.F.1.Q.1.m#i.Nauau#e.x.xbVbHb3.2.2bQbQ#6bE#6#6.5#6aD.2bQ#6bQ#6#6.2bH.x.2aK#6bQbQ#6#6aK#6bQ.E#6.2.E#6.2aKbQbQbEbQb3#6bA#6aD#6#6.2bQ#6#6.2aD#6#6aDaD#6#6#6#6#6#6#6aD#6#6.2#6aDaDaD#6.x#6aD.x#6.2aD#6#6#6#o#6#6#6#6#6#6#6#oaD#6#o#o#6#o#6#6#6#6#6.2#6#6.2aD#6.2#6aDbQ#6#6bE#6#6.2aD.2#6.2.2.2aD#6#6#6bQ#6#6#o#6bQbQ#6#6aD#o#6#o#6#6#YaD.2aDaDbQaD#6.2#6aDbQ#6aD.x.2#6.x#6#6#6.xaD#6.2#6aD.2aD.2aDaD#o.2#6aD#6#6#6#6#6aD#6.2aDaDbQ.2#6bQ#6#6bA#6aD.2#6.2.2#6.2#6aD.2.xaD.2.2#6#6#6#6#6.2#6#6#6#6.2.2#6#6#6b3#6aD.2aDaD#6aD#6.2aDaDaDaD#6aDaD.2#6aD#6#6aD#6#6#6#6#oaD#6###YaDaDaDaD##.2#6aD#6#6#Y#YaDaD#6#6#6aK.2#6#6aDaD.2aDaDaDaD.2.2#E.2#E#E.2ap.2#E.2.x.x.2.2bH.2bEb3#o#obE#obVbE#o#o#o#6#6####aD#6aDaD#E#6aD.2.2.2.2.2.x.x.2aDaDbQ#6#6bQbEbQbQaD#6aK.x#6#6aD.2aD.2#6.2#6#6aD.2#6aD#6aDaD#6#6#o#6aDaD#ob1#Y#6aDaD#5aDaD#5#EaD#EaD#EaDaD####.x#6.B#6#oaDaDaDaDaD############b1aDaDaD#6aD#o#6aD#oaD.2#6#6#6.2#6#YaD.BaD#6#6#5aD#6.xaDaD.2#EaDaDaD##aDaDaDaDaDaD#6aDaD#6#oaDaDaDaD#oaD#6aDaD#o#6#6b3aD#Y#o#oaDaDaD#6aDaD.2aDaD.2aDaD#6#6#6bQ#6#6bVaDaD.2##.2.2.2.2.2#5.O#5#4bT.gau.G#lam#G#G.Q.F.Fam.1as#X#F#d.R##aDaDaDbS#xb4#1btaQbt#8#8.#bc.4aD#6aDaD",
"aD.2##.8aE.Xaq.X#s#sbr.t#F#F#jasbq.QbB#l.F.Q#l.Q.Qam.Q.Qa.a.a..G#c.V#q.Maq.xbHaK#o#o#6#6#6.2#o#o#oaDaD#6.2aDaD.2aD.x.2aD#6bEaj#6bQaD#obQ#6#6.2bQbQaD#6bQ.2.2.2.2#6#6b3#6#6bEbQ#o#6#6#6bQ#6#6#6aD#o#6#YaDb3#6#oaDaD#6#6#6#6#6#6.xaD#6aDaD.2aDaD#6.2aD.2#6aD#6#6#6#6#6#6#o#6#6#o#6#6#6#6#o#6#6#o#6#6aD#6.2#6.2aD.2#6#6#6#6#6#o#6#6.2aDaD#6#EaD#6#EaD#6#6#6#o#6#6#6#6#6aD.2#o#o#6#6#o#6#6#6#6#6aDaD.2aD#6.2#EaD#6.xaD#6#6.x#6.xaDaD.2#E#EaD.2aD.2.2#6.2aD.2#6#6aDaD#6#6#o#o#6#6#oaD#6.2b3#6b3#oaDb3#o#6b3#oaDb3bQaK#6#6aD#o.2.2#6#6.2#6.2aD#6.2aD#6.2#6#6bQ#6#6.2aD#6.2aD#6.2aDaD.2.2aD#6.2aDaD#6#6#6#o#6#6#6#6#6#6#6#6#6#oaDaD#6aDaDaDaD#6#6#6#6#o#Y#o#YaDb3#6#obQb3b3b3#o#6.3#6#6#6#6#6.2.x.2.2#E#E.5.2aDap.2.x.x.x#6.x.2.x.2.2#6#6bE#o#Y#o#oaD#6#o##aD##.2.2##aD.2aD#6#6.x#6bH#6#6#6#6bQ#6#6bQ#6#6bE#6.2bQ#6#6aDaD#6#6aDaD#oaD#6aDaj#6#6#6#6#6#o###o#6#Yb1#Yb1aD#6####aD#EaD#EaD#E.2.2##.O##bS.O#6aj.B#6aD#6#6#6.2aDb1b1##b1b1####aD#6#6aDaD#6aDaD#6#6#6#6#6#6#6#6#6#oaDaD#6#6aD#6#6aD#E#E.2aD#EaDaDaDaDaDaD#o#6aD#6#YaD#oaD#oaD#Y#o#6#6#o#o#Y#6#o#6b3#Y#YbE#Y#o#6aDaDaDaD#6#6aD#6#6#6#o#6bQ#6#o#o#o#oaDaD##.R###E.2aDaD#6.ObS.kaX.t#j.Ga..Q.F.Q.Q.Q.Qa.a.ah.A#v.XbS##aD#Y##b1.OaEaNaqbT.X.C#y.R#5aDaD#6aD",
"aDaD#E.R###E.RaSb8#s#ga8bT.9b7aG#I.S#MaV.J#7#p#K.L.Jaz.N.G#u#u.N#q#ea7.C.x#5#5aK#6#6b3##b1#6#6#o#ob1aD#6aDaDaDaDaD#6#6aDaD#6aD#o.x#oaDbQaD#6.2bQ#6.2.2#6.2.2#6#6bQ#o#6#6#o#6aKaD#6aKbQb3#6#6bQ#6b3#6#o#6#o#6bE#6aD#6#6#6bQ#6bQ.2#6aD#6aD#6.2.2aD#6#6aD#6#6#6#6#6#o#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6aD#6#6#6#6#6#6#6#6#6#6#6#6.2aD.2aD#6.2#6aD.2#6#6#6#6#6#6#6#6#6#6#6aD#6#6#6#6#6#6#6#6#6#6#6#6.2#6#6#6.2#6#6#6aD#6.2#6#6.x#6#6#6.2#6aD.2aD#6aD.2#6#6aD#6aD#o#oaD#o#o#oaDaD#o#6bE#6#o#o#6#o#o#6#6#6#6#6#6bQ#6#6bQ#6#6aKbQ#6#6#6#6#6#6#6#6.2aD#6#6#6#6#6#6#6#6#6#6.2#6#6#6#6#6.2#6#6.2#6#6.2#6#6bQ#o#6#6#6#6#6#6aDbQ#6#o#6#6#6.2#6.2bQ#6#6b3aD#o#6#o#6#6#6bQ#6#6#o#o#6#6b3#6#6#6#6#6#6bQ.2aD.2.2.2.2.2.2.2.2.x#6.2bQ.xbQbQ.2bEbVaD#Y#6aDaD#6#6aDaDaDaDaDaDaD.2#6#6#6#6#o#6#6#6#o#6bE#6#obQ#6#6#6#obE#6#6bQaDaD#6aDaD#oaDaD#6aDaD.2#6.x#6#6#6aDaD#6#6aDb1aD#oaDaD#6aDaD.2aDaD.2aDaD.2aD###E##aD#o#6aj#o#6#6#6#6#6aD##########aDaD#6#6.2#6#6#6#6#6.2#6#6#6#6#6#6#6aD#6#6#6#6aDaj.2.2#6#6.2bQaD#####Y#6#6aD#6aDaD#6#oaD#6#o#6#o#oaD#6aDaDaD#Y#o#6#YaD#Y#Y.B#oaD#YaDaD#6aDaD##aDaDaD##aD#o#o#ob1b1#Y#o#6aD########aD####aj#5#5aSaEaq.gaG#M#.bLazac.Laxax.hauaAaA#8.ob4aS.4aDaDbS#xb4###E.O#E#E.O#5#6#6#6#6",
"####aD#######6aDaD##aDaD#E##.8#g.T.z.Ta7a8bpbT#d.9#dae#e.M.z.t.z.g.O.x#E#5.xaD#6bEbQaDaDaDaD#6aK#oaD#6#6#6#6aDaD#6#6aDbQ#6aD#6#6#6bQaK#6#6aK#6#6.EbQ.2bQbE.2aKbQbQbQ#6#6bQbAbE#6bQbQbE.EbQ#6bQ#6#6.2#6#6#6#6#6#6aD#6bQbE.2bEbQbE.2#6.2#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6aD#o#6#oaD#o#6#o#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6bQbE#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6.2aD.2aD.2aD#6#6#6#6#6.2#6#o#6aD#6#6#6aDaDaDaD#o#6#6aDb1aD##aDaDaDaD#6#6#6aDaD#6#6#6#6aDaDbQaDaDbQb3#6#6aD#6bQ#6#o#6#6#oaDaD#6aD#6#6.2.2.2aDaD#6#E.2aDaD.2aDaD#6##aD.2#6#6#6#6#6#6#6#6#6.2aD.2#6#6#6#6#6#6#6#6#6#6#6#6#6#6aD#o#o#YaDaD#6#6#6#6#6#6aD#6#6#6#6#6#6#6#6#6#6#6#6bQ#6#6aj.B#6ajaDaD#6.2aD#YaDaDaD#oaD#oaD#o#6aDaD#6aD#o#6aD#oaD#o#YaD##aD#6aD.b###YaDaDaD#YaDaD##aD#ob1b1aD#Yb1#o#oaDaDb1aD#oaDaD#o##aDaD##aDaD####.2.2#5aD#EbT.g#sa7b9#e#e.Hbv#4.H#ybT.Xb4b8#z.4bS###6#6aDaDaD#EaD.2aD##aDaD#6.x#6",
"###E.2aDaDaD#6#6aD#o.2#6#6aDaD.2.2#Eb.#y.R#E.R.x.2.R#Eb.#yb.bv#O#E.xbE#6.xaKbQ.2#6bQ#6bQaKbQbQbQ#6#6bQbQ#6#6#6#6bQ#6bQaKbAbQbQaK.2bQaK.2#6.EaKbQaK#6#6.2.2bQ.2#6aK#6#obQ#6bQbQ#o.2aKb3#6#6#6#6#6bQ#o#6#6#6#6#6#6aD#6#6#6bQb3#6#6#6#6#6#6#6#6aD#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6bQ#6#6#6b3#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6bQbE#6bQ#6aD#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6aDaD#6aD#oaD#o#o#o#6#6#6#6#6#6#oaDaD#o#6#6#6#6#6#6#o#6#6#6#6#6#o#6#6#6aDb3.2aD#6#6#6#6#6#6#6#6#oaD#o#6#6#6#6.2#6#E#6#EaD.2.2aD.2.2aD.2.2###6.2#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#o#o#6#6#6#6#6#6#6#6#6#6#6#6#6#6#6#o#6#6#6#6aD#6.BaDajaD#YaD.B#6aDaDaD#YaD#oaD#6#oaD#6#Yb1#ob1aDaDaDaD#6aDaDaD#YaD#6aD#YaDaD#o#6#oaDaDaD#o#6aDaDaD#oaD#6#6aD#6#6#6aD#oaD#o#6#o#o#6#6#6#6aDaD#6aD.2aDaD.x#Eb..Rb.#y#y#y#y#5#E.x#E#E.R#E.2.2aD.2aDaD#6aD#6#6aD.2.2aDaD#6#6.x#6"
};';
  return $buf;
} 
