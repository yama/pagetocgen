/*
Plugin Name: TOC Generator
Plugin URI:
Description: This plugin is used to automatically generate a table of contents from HTML headings on that page.
Version: 0.9.2
Author: Samit Vartak and Paul Bohman

KNOWN BUGS: 
- default value for $end_level doesn't work, you must specify it explicitly
- the start configuration marker seems to be required, even though it's not supposed to be.

TO DO:
- use a simplified syntax to call the plugin, perhaps something like: 
		*[pageTOC? &start_level=`2` &heading_tag=`h2`]* // this is where the output would go (eliminating the need for that tag)
		*[startTOC]*
		*[endTOC]*
		(Note: making the opening tag visible in the rich text editor (e.g. *[ ]*, instead of <!-- -->) has the benefit of ensuring non-technical people don't accidentally delete the comments when editing the page) 
- If I do this, create an optional backwards compatibility mode, as an external include
- extract the functions and documentation to external files in the assets folder, leaving only the parameters in plugin
- make sure multiple instances of TOCs can exist on the same page
- give the option to use existing anchors, instead of the automatically generated ones
- give the option to have no heading for the TOC
- and option to have no surrounding tag around TOC
- make code more efficient by looking for the output tag, and if it isn't there, stop running the code, so it doesn't slow down the pages that don't use the TOC plugin

 */
 
 // PARAMETERS
 
 // TOC SETTINGS
$default_start_level = 'h2';  // can be h1 through h6
$default_end_level = 'h3'; // can be h1 through h6
$default_toc_list_type = 'ul'; // type of list for table of contents; can be ul (bulleted list) or ol (numbered list)
$default_toc_heading_text = 'Page Contents'; // The text of the heading above the table of contents
$default_toc_heading_tag = 'h2'; //what level of heading to use above the table of contents
$default_toc_parent = 'div'; //the table of contents will be embeded in this tag
$default_toc_parent_id = 'toc'; //the id which gets applied to the parent tag

 // TAGS TO USE IN THE DOCUMENT
$open_param = "<!--";
$close_param = "-->";
$start_marker = "#toc_plugin#_START_TOC_INDEXING"; // begin cataloging headings here
$end_marker = "#toc_plugin#_END_TOC_INDEXING";  //end cataloging headings here
$output_marker = "#toc_plugin#_TOC_OUTPUT"; // The generated table of content will be inserted here
$start_config_marker = "#toc_plugin#_START_CONFIGURATION";
$toc_list_type_marker = "#toc_plugin#_list_type=";
$start_level_marker = "#toc_plugin#_start_level=";
$end_level_marker = "#toc_plugin#_end_level=";
$toc_heading_text_marker = "#toc_plugin#_header=";
$toc_heading_marker = "#toc_plugin#_header_tag=";
$toc_parent_marker = "#toc_plugin#_parent_tag=";
$toc_parent_id_marker = "#toc_plugin#_parent_tag_id=";
$end_config_marker = "#toc_plugin#_END_CONFIGURATION";

// END PARAMETERS
// BEGIN PLUGIN CODE

//Information gathering
$source = &$modx->documentOutput; //fetching the page source

$search_content1 = $open_param.$toc_list_type_marker.'(.*)'.$close_param; //fetching the list type
preg_match($search_content1, $source, $option1);
if ($option1[1] !='') { $toc_list_type = $option1[1]; } else $toc_list_type = $default_toc_list_type; 

$search_content2 = $open_param.$start_level_marker.'(.*)'.$close_param; //fetching the start level
preg_match($search_content2, $source, $option2);
if ($option2[1] !='') { $start_level = $option2[1]; } else $start_level = $default_start_level; 

$search_content3 = $open_param.$end_level_marker.'(.*)'.$close_param; //fetching the end level
preg_match($search_content3, $source, $option3);
if ($option3[1] !='') { $end_level = $option3[1]; } else $end_level = $default_end_level; 

$search_content4 = $open_param.$toc_heading_text_marker.'(.*)'.$close_param; //fetching the header text
preg_match($search_content4, $source, $option4);
if ($option4[1] !='') { $toc_heading_text = $option4[1]; } else $toc_heading_text = $default_toc_heading_text;

$search_content5 = $open_param.$toc_heading_marker.'(.*)'.$close_param; //fetching the header tag which contains the header
preg_match($search_content5, $source, $option5);
if ($option5[1] !='') { $toc_heading_tag = $option5[1]; } else $toc_heading_tag = $default_toc_heading_tag;

$search_content6 = $open_param.$toc_parent_marker.'(.*)'.$close_param; //fetching the tag which will enclose table of contents
preg_match($search_content6, $source, $option6);
if ($option6[1] !='') { $toc_parent = $option6[1]; } else $toc_parent = $default_toc_parent;

$search_content7 = $open_param.$toc_parent_id_marker.'(.*)'.$close_param; //fetching the CSS id which we want to apply to table of contents
preg_match($search_content7, $source, $option7);
if ($option7[1] !='') { $toc_parent_id = $option7[1]; } else $toc_parent_id = $default_toc_parent_id;


//Functions
function strip_special_chars($val)
{
	$return_str = "";
	for($i=1; $i <= strlen($val); $i++)
	{
		if ( ((ord(substr($val, $i-1, 1)) >= 97) and (ord(substr($val, $i-1, 1)) <= 122)) or ((ord(substr($val, $i-1, 1)) >= 65) and (ord(substr($val, $i-1, 1)) <= 90)) or ((ord(substr($val, $i-1, 1)) >= 48) and (ord(substr($val, $i-1, 1)) <= 57)))
		{
			$return_str .= substr($val, $i-1, 1);
		}
		else if(ord(substr($val, $i-1, 1)) == 32) 
		{
			$return_str .= "_";		
		}
	}
	return($return_str);
}
//Plugin code starts
$search_content = '/[^|]('.$start_marker.')(.+?)('.$end_marker.')/sim';
preg_match($search_content, $source, $actual_source);
$content = $actual_source[0];
$search_header = '=<h['.$start_level.'-'.$end_level.'][^>]*>(.*)</h['.$start_level.'-'.$end_level.']>=siU';
preg_match_all($search_header, $content, $header_tags_info, PREG_SET_ORDER);

$named_anchors = array();
$header_tags = array();
foreach ($header_tags_info as $val) {
	array_push($header_tags,$val[0]);
	array_push($named_anchors,$val[1]);
}
$i = 0;
if ($toc_heading_tag!='')
	{
	$hx = "<".$toc_heading_tag.">".$toc_heading_text."</".$toc_heading_tag.">";
	}
else $hx='';
if($toc_parent == ""){
$initial_tag = $hx."\n"."<". $toc_list_type ." id=\"".$toc_parent_id."\">";
$final_tag = "\n</".$toc_list_type.">";
}else{
$initial_tag = "\n<". $toc_parent ." id=\"".$toc_parent_id."\">"."\n".$hx."\n<". $toc_list_type .">";
$final_tag = "\n</".$toc_list_type.">\n</".$toc_parent.">";
}
$display_content = $initial_tag;  
$prev_tag = "";
$prev_tag_value = 7;
$current_tag_pointer = "";
$tag_pattern = '=<h['.$start_level.'-'.$end_level.'][^>]*>=siU';
$h1=array();
$h2=array();
$h3=array();
$h4=array();
$h5=array();
$h6=array();
foreach($header_tags as $tags){
	$tag = "";
	$tag_value = 0;
	$replace_var = "";
	if (strpos($header_tags[$i], '<h1')!==false){
		//$tag = "<h1>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 1;
		$current_tag_pointer = $h1;
	}
	elseif (strpos($header_tags[$i], '<h2')!==false) {
		//$tag = "<h2>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 2;
		$current_tag_pointer = $h2;
	}
	elseif (strpos($header_tags[$i], '<h3')!==false) {
		//$tag = "<h3>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 3;
		$current_tag_pointer = $h3;
	}
	elseif (strpos($header_tags[$i], '<h4')!==false) {
		//$tag = "<h4>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 4;
		$current_tag_pointer = $h4;
	}
	elseif (strpos($header_tags[$i], '<h5')!==false) {
		//$tag = "<h5>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 5;
		$current_tag_pointer = $h5;
	}
	elseif (strpos($header_tags[$i], '<h6')!==false) {
		//$tag = "<h6>";
		preg_match_all($tag_pattern, $header_tags[$i], $tag1, PREG_SET_ORDER);
		$tag2 = $tag1[0];
		$tag = $tag2[0];
		$tag_value = 6;
		$current_tag_pointer = $h6;
	}
	$temp = $i + 1;
	$replace_var = $tag."<a name=\"". strip_special_chars(strip_tags($named_anchors[$i])). "_". $temp ."\" id=\"". strip_special_chars(strip_tags($named_anchors[$i])). "_". $temp."\"></a>".$named_anchors[$i]."</h".$tag_value.">";
	$source = str_replace($tags, $replace_var, $source);
	if($prev_tag_value < $tag_value){
		$display_content = $display_content . "\n<". $toc_list_type .">";
		$display_content = $display_content . "\n<li><a href=\"".$_SERVER["REQUEST_URI"]."#".strip_special_chars(strip_tags($named_anchors[$i]))."_".$temp."\">". 
strip_tags($named_anchors[$i]) ."</a>";

		if($tag_value == 6){
			array_unshift( $h6, "\n</". $toc_list_type .">");
			array_unshift( $h6, "</li>");
		}elseif($tag_value == 5){
			array_unshift( $h5, "\n</". $toc_list_type .">");
			array_unshift( $h5, "</li>");
		}elseif($tag_value == 4){
			array_unshift( $h4, "\n</". $toc_list_type .">");
			array_unshift( $h4, "</li>");
		}elseif($tag_value == 3){
			array_unshift( $h3, "\n</". $toc_list_type .">");
			array_unshift( $h3, "</li>");
		}elseif($tag_value == 2){
			array_unshift( $h2, "\n</". $toc_list_type .">");
			array_unshift( $h2, "</li>");
		}elseif($tag_value == 1){
			array_unshift( $h1, "\n</". $toc_list_type .">");
			array_unshift( $h1, "</li>");
		}
	}
	else{
		if($tag_value < 6){
			foreach($h6 as $value){
				$display_content = $display_content .$value;
			}
			$h6 = array( Null );
		}
		if($tag_value < 5){
			foreach($h5 as $value){
				$display_content = $display_content .$value;
			}
			$h5 = array( Null );
		}
		if($tag_value < 4){
			foreach($h4 as $value){
				$display_content = $display_content .$value;
			}
			$h4 = array( Null );
		}
		if($tag_value < 3){
			foreach($h3 as $value){
				$display_content = $display_content .$value;
			}
			$h3 = array( Null );
		}
		if($tag_value < 2){
			foreach($h2 as $value){
				$display_content = $display_content .$value;	
			}
			$h2 = array( Null );
		}
		if($tag_value < 1){
			foreach($h1 as $value){
				$display_content = $display_content .$value;
			}
			$h1 = array( Null );
		}
		if($tag_value == 6){
			$display_content = $display_content .array_shift($h6);
		}
		if($tag_value == 5){
			$display_content = $display_content .array_shift($h5);
		}
		if($tag_value == 4){
			$display_content = $display_content .array_shift($h4);
		}
		if($tag_value == 3){
			$display_content = $display_content .array_shift($h3);
		}
		if($tag_value == 2){
			$display_content = $display_content .array_shift($h2);
		}
		if($tag_value == 1){
			$display_content = $display_content .array_shift($h1);
		}
		$display_content = $display_content . "\n<li><a href=\"".$_SERVER["REQUEST_URI"]."#".strip_special_chars(strip_tags($named_anchors[$i]))."_".$temp."\">". strip_tags($named_anchors[$i]) ."</a>";

		if($tag_value == 6){
			array_unshift( $h6, "</li>");			
		}elseif($tag_value == 5){
			array_unshift( $h5, "</li>");
		}elseif($tag_value == 4){
			array_unshift( $h4, "</li>");
		}elseif($tag_value == 3){
			array_unshift( $h3, "</li>");
		}elseif($tag_value == 2){
			array_unshift( $h2, "</li>");
		}elseif($tag_value == 1){
			array_unshift( $h1, "</li>");
		}
	}
	$prev_tag = $tag;
	$prev_tag_value = $tag_value;
	$i++;
}
$empty = "";
$display_content =$display_content. "</li>".$final_tag;


//Remove toc codes from the source.
$source = str_replace($open_param.$start_config_marker.$close_param, $display_content, $source);
$source = str_replace($open_param.$toc_list_type_marker.$toc_list_type.$close_param, '', $source);
$source = str_replace($open_param.$start_level_marker.$start_level.$close_param, '', $source);
$source = str_replace($open_param.$end_level_marker.$end_level.$close_param, '', $source);
$source = str_replace($open_param.$toc_heading_text_marker.$toc_heading_text.$close_param, '', $source);
$source = str_replace($open_param.$toc_heading_marker.$toc_heading_tag.$close_param, '', $source);
$source = str_replace($open_param.$toc_parent_marker.$toc_parent.$close_param, '', $source);
$source = str_replace($open_param.$toc_parent_id_marker.$toc_parent_id.$close_param, '', $source);
$source = str_replace($open_param.$start_marker.$close_param, '', $source);
$source = str_replace($open_param.$end_config_marker.$close_param, '', $source);
$source = str_replace($open_param.$output_marker.$close_param, '', $source);
$source = str_replace($open_param.$end_marker.$close_param, '', $source);
