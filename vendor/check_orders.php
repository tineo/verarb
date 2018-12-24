<?php
error_reporting (E_ALL);
chdir (dirname (__FILE__));

// This is so awesome -- DRY!
$dbinfo = Spyc::YAMLLoad('../config/database.yml');

// You can especify which DB to use via a parameter:
// development, production or test -- by default it's production
if ($_SERVER['argc'] > 1) {
    $i = $_SERVER['argv'][1];
}
else {
    $i = "production";
}

$t = $dbinfo[$i];

$db = db_connect ("mysql://" . $t['username'] . ":" . $t['password'] . "@" . $t['host'] . "/" . $t['database']);

$sql = "SELECT proyectos.id
          FROM proyectos,
               opportunities
         WHERE proyectos.opportunity_id=opportunities.id
           AND sales_stage='Closed Won'
           AND proyectos.orden_de_trabajo='0'
           AND opportunities.deleted='0'
      ORDER BY opportunities.date_closed";

$result = db_get ($db, $sql);

if ($result != false) {
    // We get the last number of the Order to follow the sequence
    $sql = "SELECT MAX(orden_de_trabajo) AS numero
              FROM proyectos";
    $o = db_getone ($db, $sql);
    $n = $o['numero'];
    
    if ($n == 0) {
        // Starting fresh? Ok, use this number then
        $n = date ("ym0000");
    }
    else {
        $n = $n + 1;
        // Pad the thing
        $n = order_pad ($n);
        
        // Let's check the special case for a New Year
        if (substr ($n, 0, 2) != date ("y")) {
            $n = date ("ym") . "0000";
        }
    }
    
    foreach ($result as $r) {
        $data = array (
            'orden_de_trabajo' => $n
        );
        db_update ($db, 'proyectos', $data, "id='" . $r['id'] . "'");
        
        $n = order_pad ($n + 1);
    }
}



function order_pad ($n) {
    return str_pad ($n, 8, "0", STR_PAD_LEFT);
}


// ----------------------------------------------------------------------------

// Deborah v1.1.0
// A fine piece of junk written by Jaime G. Wong <j@jgwong.org>
// Deborah is an abstraction library for DB connections. No objects, just
// pure, oldskool, functional bliss.
//
// Copyright © 2005 Jaime G. Wong <j@jgwong.org>
// Permission to use, copy, modify, distribute, and sell this software and its
// documentation for any purpose is hereby granted without fee, provided that
// the above copyright notice appear in all copies and that both that
// copyright notice and this permission notice appear in supporting
// documentation.  No representations are made about the suitability of this
// software for any purpose.  It is provided "as is" without express or 
// implied warranty.
//
// Historic changes (please note your changes here):
//
// 20050204 jaime g. wong <j@jgwong.org>
//     - Several modifications, renamed to Deborah, started this log :)
//     - Now has some Mathilde-isms, particularly panic() to date. So if you
//       want to use it out of the Mathilde context, just define a panic()
//       function and hope I'll continue commenting dependencies here. ;)
//     - db_connect now uses a PEAR-like DSN. It's more convenient, at least to
//       me. Sorry for the people who hate DSNs. :)
// 20050807 jaime g. wong <j@jgwong.org>
//     - Added a check if the DEBORAH_DBTYPE is defined or not before defining
//       it.
// 20051018 jaime g. wong <j@jgwong.org>
//     - Added support for Postgres sequences.
// 20051027 jaime g. wong <j@jgwong.org>
//     - Added new functions: db_find (), db_getone ()
//     - Added a new parameter to db_get () to return just one row. But it's
//       suggested to use the db_getone which is a wrapper so source code can
//       be more readable instead of a cryptic parameter.
//     - Translated all comments to english. :)
// 20051108 jaime g. wong <j@jgwong.org>
//     - Added a verification if the DSN is well-formed.
// 20051117 jaime g. wong <j@jgwong.org>
//     - Password from DSN was being taken wrong.
// 20051122 jaime g. wong <j@jgwong.org>
//     - If you specify an ID on db_find(), it will do a db_getone().
// 20051208 jaime g. wong <j@jgwong.org>
//     - Now we're working with Magic Quotes off. This is a huge change so we
//       escape strings using MySQL and Postgres' own escaping functions (which
//       is highly recommended). This works transparently, just be sure not to
//       pass escaped strings.
//     - Created db_destroy (). Read the code, it's straightforward.

function db_connect ($dsn) {
// Returns a PEAR::DB connection using a PEAR-style DSN
    if (!preg_match( '/^(\w*):\/\/(\w*)(:(\w*))?@(\w*)\/(\w*)$/', $dsn, $matches)) {
        panic ('<b>Deborah:</b> Undefined or malformed DSN. Given was "' . $dsn . '".');
    }
    
    $dbtype   = $matches[1];
    $server   = $matches[5];
    $database = $matches[6];
    $username = $matches[2];
    $passwd   = $matches[4];
    
    if ($dbtype == 'mysql') {
        $db = mysql_connect ($server, $username, $passwd);
        
        if (!$db) {
            panic ('<b>Deborah:</b> Can\'t connect to database! DSN given was "'  . $dsn . '".');
        }
    
        if (!mysql_select_db ($database, $db)) {
            panic ("<b>Deborah:</b> Can't select the MySQL database! -- mysql_error: " . mysql_error ($db));
        }
        
        if (!defined ('DEBORAH_DBTYPE')) {
            define ('DEBORAH_DBTYPE', 'mysql');
        }
    }
    elseif ($dbtype == 'pgsql') {
        $db = pg_connect ("host=" . $server . " dbname=" . $database . " user=" . $username . " password=" . $passwd);
        if (!$db) {
            panic("<b>Deborah:</b> Can't connect to the database! DSN given was " . $dsn);
        }
        
        if (!defined ('DEBORAH_DBTYPE')) {
            define ('DEBORAH_DBTYPE', 'pgsql');
        }
    }
    else {
        panic ('<b>Deborah:</b> Database type "' . $dbtype . '" unrecognized');
    }
    
    return $db;
}


function db_insert ($db, $table, $fields) {
    $fieldlist = "";
    $valuelist = "";
    foreach ($fields as $field => $value) {
        $value =  db_escape ($value);
        
        $fieldlist .= ($fieldlist==""?"":", ") . $field;
        $valuelist .= ($valuelist==""?"":", ") . "'" . $value . "'";
    }

    $sql = "INSERT INTO " . $table . " (" . $fieldlist . ") VALUES (" . $valuelist .")";

    db_exec ($db, $sql);

    return true;
}


function db_update ($db, $table, $fields, $where) {
    $valuelist = "";
    foreach ($fields as $field => $value) {
        $value =  db_escape ($value);
                
        $valuelist .= ($valuelist == "" ? "" : ", ") . $field . "='" . $value . "'";
    }
    
    $sql = "UPDATE " . $table . " SET " . $valuelist;
    
    if ($where != "") {
        $sql .= " WHERE " . $where;
    }

    db_exec ($db, $sql);

    return true;
}


function db_delete ($db, $table, $where) {
     $sql = "DELETE FROM $table";
     if ($where != "") {
         $sql .= " WHERE " . $where;
     }
    db_exec ($db, $sql);

    return true;
}


function db_exec ($db, $sql) {
// Executes a query, returns the result
    if (DEBORAH_DBTYPE == 'mysql') {
        $result = mysql_query ($sql, $db);
        if (!$result) {
            panic ('<b>Deborah db_exec():</b>' . mysql_error ($db) . " in " . $_SERVER["PATH_TRANSLATED"] . ".\nQuery string is: " . $sql);
            exit();
        }
    }
    elseif (DEBORAH_DBTYPE == 'pgsql') {
        $result = pg_query ($db, $sql);
        if (!$result) {
            panic ('<b>Deborah db_exec():</b>' . pg_result_error ($db) . " in " . $_SERVER["PATH_TRANSLATED"] . ".\nQuery string is: " . $sql);
            exit();
        }
    }
    else {
       panic ('<b>Deborah db_exec():</b> Database type "' . DEBORAH_DBTYPE . '" unrecognized');
    }
    
    return $result;
}


function db_get ($db, $sql, $one = false) {
// Execs a SELECT query and automagically returns all the resulting rows in a
// multidimensional array. If you set the $one variable to boolean true the
// first row is returned.
// It is advised to use the db_getone () instead of setting $one, as it makes
// source code more readable.
    $result = db_exec ($db, $sql);
    
    if (DEBORAH_DBTYPE == 'mysql') {
        $c = mysql_num_rows ($result);
    
        if ($c == 0) {
            return false;
        }
        else {
            if ($one === false) {
                for ($i = 0; $i < $c; $i++) {
                    $return[] = mysql_fetch_array ($result, MYSQL_ASSOC);
                }
            }
            else {
                $return = mysql_fetch_array ($result, MYSQL_ASSOC);
            }
            return $return;
        }
    }
    elseif (DEBORAH_DBTYPE == 'pgsql') {
        $c = pg_num_rows ($result);

        if ($c == 0) {
            return false;
        }
        else {
            if ($one === false) {
                for ($i = 0; $i < $c; $i++) {
                    $return[] = pg_fetch_array ($result, $i, PGSQL_ASSOC);
                }
            }
            else {
                $return =  pg_fetch_array ($result, 0, PGSQL_ASSOC);
            }
            return $return;
        }
    }
    else {
       panic ('<b>Deborah db_get():</b> No conozco el tipo de base de datos "' . DEBORAH_DBTYPE . '"');
    }
    
}


function db_getone ($db, $sql) {
    return db_get ($db, $sql, true);
}


function db_getlist ($db, $table, $key, $value, $where = '', $orderby = '') {
// Returns a "list," an unidimensional array based on the table given and the
// $key and $value fields specified.
//
// e.g.: query_getlist($db, "students", "studentid", "name") returns an array
// with the keys taken from the 'studentid' field and the values to the 'name'
// field.
    $sql = "SELECT " . $key . ", " . $value . " FROM " . $table;

    if ($where != '') {
        $sql .= " WHERE " . $where;
    }

    if ($orderby != '') {
        $sql .= " ORDER BY " . $orderby;
    }
    else {
        $sql .= " ORDER BY " . $value;
    }

    $result = db_get ($db, $sql);

    $c = count ($result);

    if ($c == 0) {
        return array();
    }
    else {
        for ($i = 0; $i < $c; $i++) {
            $that = $result[$i];
            $return[ $that[$key] ] = $that[$value];
        }
        return $return;
    }
}


function db_getnextval ($db, $sequence) {
// Returns the next value in a sequence.
// If it's MySQL we use a separate table containing a single field called 'id'.
// If it's Postgres, it's a real sequence.
    if (DEBORAH_DBTYPE == 'mysql') {
        db_exec ($db, 'BEGIN');
        
        $sql = "SELECT id + 1 AS value FROM " . $sequence;
        $r = db_get ($db, $sql);
        $val = $r[0]['value'];
        
        $sql = 'UPDATE ' . $sequence . " SET id='" . $val . "'";
        db_exec ($db, $sql);
        
        db_exec ($db, 'COMMIT');
    }
    else {
        $r = db_get ($db, "SELECT NEXTVAL('" . $sequence . "')");
        $val = $r[0]['nextval'];
    }
    return $val;
}


function db_find ($db, $table, $id = '', $order = 'id') {
// Execs a SELECT * by an optional ID.
// My table schemas always have an 'id' field.
    $sql = "SELECT * FROM " . $table . " ";
    
    if ($id != '') {
        $sql .= "WHERE id='" . $id . "' ";
    }
    
    $sql .= "ORDER BY " . $order;
    
    if ($id != '') {
        return db_getone ($db, $sql);
    }
    else {
        return db_get ($db, $sql);
    }
}


function db_destroy ($db, $table, $id) {
// Deletes a row where the $table's ID field (named "ID" as is my standard)
// is '$id'. Just a handy function.
    db_delete ($db, $table, "id='" . $id . "'");
}


function db_escape ($string) {
// Escapes the string according to the DB type
    if (DEBORAH_DBTYPE == 'mysql') {
        return  mysql_real_escape_string ($string);
    }
    elseif (DEBORAH_DBTYPE == 'pgsql') {
        return  pg_escape_string ($string);
    }
    else {
        warning ('<b>Deborah:</b> I don\'t know how to escape strings with this DB type!');
    }
}



  /**
   * Spyc -- A Simple PHP YAML Class
   * @version 0.2.(5) -- 2006-12-31
   * @author Chris Wanstrath <chris@ozmm.org>
   * @author Vlad Andersen <vlad@oneiros.ru>
   * @link http://spyc.sourceforge.net/
   * @copyright Copyright 2005-2006 Chris Wanstrath
   * @license http://www.opensource.org/licenses/mit-license.php MIT License
   * @package Spyc
   */

  /**
   * A node, used by Spyc for parsing YAML.
   * @package Spyc
   */
  class YAMLNode {
    /**#@+
     * @access public
     * @var string
     */
    var $parent;
    var $id;
    /**#@+*/
    /**
     * @access public
     * @var mixed
     */
    var $data;
    /**
     * @access public
     * @var int
     */
    var $indent;
    /**
     * @access public
     * @var bool
     */
    var $children = false;

    /**
     * The constructor assigns the node a unique ID.
     * @access public
     * @return void
     */
    function YAMLNode($nodeId) {
      $this->id = $nodeId;
    }
  }

  /**
   * The Simple PHP YAML Class.
   *
   * This class can be used to read a YAML file and convert its contents
   * into a PHP array.  It currently supports a very limited subsection of
   * the YAML spec.
   *
   * Usage:
   * <code>
   *   $parser = new Spyc;
   *   $array  = $parser->load($file);
   * </code>
   * @package Spyc
   */
  class Spyc {

    /**
     * Load YAML into a PHP array statically
     *
     * The load method, when supplied with a YAML stream (string or file),
     * will do its best to convert YAML in a file into a PHP array.  Pretty
     * simple.
     *  Usage:
     *  <code>
     *   $array = Spyc::YAMLLoad('lucky.yaml');
     *   print_r($array);
     *  </code>
     * @access public
     * @return array
     * @param string $input Path of YAML file or string containing YAML
     */
    function YAMLLoad($input) {
      $spyc = new Spyc;
      return $spyc->load($input);
    }

    /**
     * Dump YAML from PHP array statically
     *
     * The dump method, when supplied with an array, will do its best
     * to convert the array into friendly YAML.  Pretty simple.  Feel free to
     * save the returned string as nothing.yaml and pass it around.
     *
     * Oh, and you can decide how big the indent is and what the wordwrap
     * for folding is.  Pretty cool -- just pass in 'false' for either if
     * you want to use the default.
     *
     * Indent's default is 2 spaces, wordwrap's default is 40 characters.  And
     * you can turn off wordwrap by passing in 0.
     *
     * @access public
     * @return string
     * @param array $array PHP array
     * @param int $indent Pass in false to use the default, which is 2
     * @param int $wordwrap Pass in 0 for no wordwrap, false for default (40)
     */
    function YAMLDump($array,$indent = false,$wordwrap = false) {
      $spyc = new Spyc;
      return $spyc->dump($array,$indent,$wordwrap);
    }

    /**
     * Load YAML into a PHP array from an instantiated object
     *
     * The load method, when supplied with a YAML stream (string or file path),
     * will do its best to convert the YAML into a PHP array.  Pretty simple.
     *  Usage:
     *  <code>
     *   $parser = new Spyc;
     *   $array  = $parser->load('lucky.yaml');
     *   print_r($array);
     *  </code>
     * @access public
     * @return array
     * @param string $input Path of YAML file or string containing YAML
     */
    function load($input) {
      // See what type of input we're talking about
      // If it's not a file, assume it's a string
      if (!empty($input) && (strpos($input, "\n") === false)
          && file_exists($input)) {
        $yaml = file($input);
      } else {
        $yaml = explode("\n",$input);
      }
      // Initiate some objects and values
      $base              = new YAMLNode (1);
      $base->indent      = 0;
      $this->_lastIndent = 0;
      $this->_lastNode   = $base->id;
      $this->_inBlock    = false;
      $this->_isInline   = false;
      $this->_nodeId     = 2;

      foreach ($yaml as $linenum => $line) {
        $ifchk = trim($line);

        // If the line starts with a tab (instead of a space), throw a fit.
        if (preg_match('/^(\t)+(\w+)/', $line)) {
          $err = 'ERROR: Line '. ($linenum + 1) .' in your input YAML begins'.
                 ' with a tab.  YAML only recognizes spaces.  Please reformat.';
          die($err);
        }

        if ($this->_inBlock === false && empty($ifchk)) {
          continue;
        } elseif ($this->_inBlock == true && empty($ifchk)) {
          $last =& $this->_allNodes[$this->_lastNode];
          $last->data[key($last->data)] .= "\n";
        } elseif ($ifchk{0} != '#' && substr($ifchk,0,3) != '---') {
          // Create a new node and get its indent
          $node         = new YAMLNode ($this->_nodeId);
		  $this->_nodeId++;

          $node->indent = $this->_getIndent($line);

          // Check where the node lies in the hierarchy
          if ($this->_lastIndent == $node->indent) {
            // If we're in a block, add the text to the parent's data
            if ($this->_inBlock === true) {
              $parent =& $this->_allNodes[$this->_lastNode];
              $parent->data[key($parent->data)] .= trim($line).$this->_blockEnd;
            } else {
              // The current node's parent is the same as the previous node's
              if (isset($this->_allNodes[$this->_lastNode])) {
                $node->parent = $this->_allNodes[$this->_lastNode]->parent;
              }
            }
          } elseif ($this->_lastIndent < $node->indent) {
            if ($this->_inBlock === true) {
              $parent =& $this->_allNodes[$this->_lastNode];
              $parent->data[key($parent->data)] .= trim($line).$this->_blockEnd;
            } elseif ($this->_inBlock === false) {
              // The current node's parent is the previous node
              $node->parent = $this->_lastNode;

              // If the value of the last node's data was > or | we need to
              // start blocking i.e. taking in all lines as a text value until
              // we drop our indent.
              $parent =& $this->_allNodes[$node->parent];
              $this->_allNodes[$node->parent]->children = true;
              if (is_array($parent->data)) {
                $chk = '';
                if (isset ($parent->data[key($parent->data)]))
                    $chk = $parent->data[key($parent->data)];
                if ($chk === '>') {
                  $this->_inBlock  = true;
                  $this->_blockEnd = ' ';
                  $parent->data[key($parent->data)] =
                        str_replace('>','',$parent->data[key($parent->data)]);
                  $parent->data[key($parent->data)] .= trim($line).' ';
                  $this->_allNodes[$node->parent]->children = false;
                  $this->_lastIndent = $node->indent;
                } elseif ($chk === '|') {
                  $this->_inBlock  = true;
                  $this->_blockEnd = "\n";
                  $parent->data[key($parent->data)] =
                        str_replace('|','',$parent->data[key($parent->data)]);
                  $parent->data[key($parent->data)] .= trim($line)."\n";
                  $this->_allNodes[$node->parent]->children = false;
                  $this->_lastIndent = $node->indent;
                }
              }
            }
          } elseif ($this->_lastIndent > $node->indent) {
            // Any block we had going is dead now
            if ($this->_inBlock === true) {
              $this->_inBlock = false;
              if ($this->_blockEnd = "\n") {
                $last =& $this->_allNodes[$this->_lastNode];
                $last->data[key($last->data)] =
                      trim($last->data[key($last->data)]);
              }
            }

            // We don't know the parent of the node so we have to find it
            // foreach ($this->_allNodes as $n) {
            foreach ($this->_indentSort[$node->indent] as $n) {
              if ($n->indent == $node->indent) {
                $node->parent = $n->parent;
              }
            }
          }

          if ($this->_inBlock === false) {
            // Set these properties with information from our current node
            $this->_lastIndent = $node->indent;
            // Set the last node
            $this->_lastNode = $node->id;
            // Parse the YAML line and return its data
            $node->data = $this->_parseLine($line);
            // Add the node to the master list
            $this->_allNodes[$node->id] = $node;
            // Add a reference to the parent list
            $this->_allParent[intval($node->parent)][] = $node->id;
            // Add a reference to the node in an indent array
            $this->_indentSort[$node->indent][] =& $this->_allNodes[$node->id];
            // Add a reference to the node in a References array if this node
            // has a YAML reference in it.
            if (
              ( (is_array($node->data)) &&
                isset($node->data[key($node->data)]) &&
                (!is_array($node->data[key($node->data)])) )
              &&
              ( (preg_match('/^&([^ ]+)/',$node->data[key($node->data)]))
                ||
                (preg_match('/^\*([^ ]+)/',$node->data[key($node->data)])) )
            ) {
                $this->_haveRefs[] =& $this->_allNodes[$node->id];
            } elseif (
              ( (is_array($node->data)) &&
                isset($node->data[key($node->data)]) &&
                 (is_array($node->data[key($node->data)])) )
            ) {
              // Incomplete reference making code.  Ugly, needs cleaned up.
              foreach ($node->data[key($node->data)] as $d) {
                if ( !is_array($d) &&
                  ( (preg_match('/^&([^ ]+)/',$d))
                    ||
                    (preg_match('/^\*([^ ]+)/',$d)) )
                  ) {
                    $this->_haveRefs[] =& $this->_allNodes[$node->id];
                }
              }
            }
          }
        }
      }
      unset($node);

      // Here we travel through node-space and pick out references (& and *)
      $this->_linkReferences();

      // Build the PHP array out of node-space
      $trunk = $this->_buildArray();
      return $trunk;
    }

    /**
     * Dump PHP array to YAML
     *
     * The dump method, when supplied with an array, will do its best
     * to convert the array into friendly YAML.  Pretty simple.  Feel free to
     * save the returned string as tasteful.yaml and pass it around.
     *
     * Oh, and you can decide how big the indent is and what the wordwrap
     * for folding is.  Pretty cool -- just pass in 'false' for either if
     * you want to use the default.
     *
     * Indent's default is 2 spaces, wordwrap's default is 40 characters.  And
     * you can turn off wordwrap by passing in 0.
     *
     * @access public
     * @return string
     * @param array $array PHP array
     * @param int $indent Pass in false to use the default, which is 2
     * @param int $wordwrap Pass in 0 for no wordwrap, false for default (40)
     */
    function dump($array,$indent = false,$wordwrap = false) {
      // Dumps to some very clean YAML.  We'll have to add some more features
      // and options soon.  And better support for folding.

      // New features and options.
      if ($indent === false or !is_numeric($indent)) {
        $this->_dumpIndent = 2;
      } else {
        $this->_dumpIndent = $indent;
      }

      if ($wordwrap === false or !is_numeric($wordwrap)) {
        $this->_dumpWordWrap = 40;
      } else {
        $this->_dumpWordWrap = $wordwrap;
      }

      // New YAML document
      $string = "---\n";

      // Start at the base of the array and move through it.
      foreach ($array as $key => $value) {
        $string .= $this->_yamlize($key,$value,0);
      }
      return $string;
    }

    /**** Private Properties ****/

    /**#@+
     * @access private
     * @var mixed
     */
    var $_haveRefs;
    var $_allNodes;
    var $_allParent;
    var $_lastIndent;
    var $_lastNode;
    var $_inBlock;
    var $_isInline;
    var $_dumpIndent;
    var $_dumpWordWrap;
    /**#@+*/

    /**** Public Properties ****/

    /**#@+
     * @access public
     * @var mixed
     */
    var $_nodeId;
    /**#@+*/

    /**** Private Methods ****/

    /**
     * Attempts to convert a key / value array item to YAML
     * @access private
     * @return string
     * @param $key The name of the key
     * @param $value The value of the item
     * @param $indent The indent of the current node
     */
    function _yamlize($key,$value,$indent) {
      if (is_array($value)) {
        // It has children.  What to do?
        // Make it the right kind of item
        $string = $this->_dumpNode($key,NULL,$indent);
        // Add the indent
        $indent += $this->_dumpIndent;
        // Yamlize the array
        $string .= $this->_yamlizeArray($value,$indent);
      } elseif (!is_array($value)) {
        // It doesn't have children.  Yip.
        $string = $this->_dumpNode($key,$value,$indent);
      }
      return $string;
    }

    /**
     * Attempts to convert an array to YAML
     * @access private
     * @return string
     * @param $array The array you want to convert
     * @param $indent The indent of the current level
     */
    function _yamlizeArray($array,$indent) {
      if (is_array($array)) {
        $string = '';
        foreach ($array as $key => $value) {
          $string .= $this->_yamlize($key,$value,$indent);
        }
        return $string;
      } else {
        return false;
      }
    }

    /**
     * Returns YAML from a key and a value
     * @access private
     * @return string
     * @param $key The name of the key
     * @param $value The value of the item
     * @param $indent The indent of the current node
     */
    function _dumpNode($key,$value,$indent) {
      // do some folding here, for blocks
      if (strpos($value,"\n") !== false || strpos($value,": ") !== false || strpos($value,"- ") !== false) {
        $value = $this->_doLiteralBlock($value,$indent);
      } else {
        $value  = $this->_doFolding($value,$indent);
      }

      if (is_bool($value)) {
        $value = ($value) ? "true" : "false";
      }

      $spaces = str_repeat(' ',$indent);

      if (is_int($key)) {
        // It's a sequence
        $string = $spaces.'- '.$value."\n";
      } else {
        // It's mapped
        $string = $spaces.$key.': '.$value."\n";
      }
      return $string;
    }

    /**
     * Creates a literal block for dumping
     * @access private
     * @return string
     * @param $value
     * @param $indent int The value of the indent
     */
    function _doLiteralBlock($value,$indent) {
      $exploded = explode("\n",$value);
      $newValue = '|';
      $indent  += $this->_dumpIndent;
      $spaces   = str_repeat(' ',$indent);
      foreach ($exploded as $line) {
        $newValue .= "\n" . $spaces . trim($line);
      }
      return $newValue;
    }

    /**
     * Folds a string of text, if necessary
     * @access private
     * @return string
     * @param $value The string you wish to fold
     */
    function _doFolding($value,$indent) {
      // Don't do anything if wordwrap is set to 0
      if ($this->_dumpWordWrap === 0) {
        return $value;
      }

      if (strlen($value) > $this->_dumpWordWrap) {
        $indent += $this->_dumpIndent;
        $indent = str_repeat(' ',$indent);
        $wrapped = wordwrap($value,$this->_dumpWordWrap,"\n$indent");
        $value   = ">\n".$indent.$wrapped;
      }
      return $value;
    }

    /* Methods used in loading */

    /**
     * Finds and returns the indentation of a YAML line
     * @access private
     * @return int
     * @param string $line A line from the YAML file
     */
    function _getIndent($line) {
      preg_match('/^\s{1,}/',$line,$match);
      if (!empty($match[0])) {
        $indent = substr_count($match[0],' ');
      } else {
        $indent = 0;
      }
      return $indent;
    }

    /**
     * Parses YAML code and returns an array for a node
     * @access private
     * @return array
     * @param string $line A line from the YAML file
     */
    function _parseLine($line) {
      $line = trim($line);

      $array = array();

      if (preg_match('/^-(.*):$/',$line)) {
        // It's a mapped sequence
        $key         = trim(substr(substr($line,1),0,-1));
        $array[$key] = '';
      } elseif ($line[0] == '-' && substr($line,0,3) != '---') {
        // It's a list item but not a new stream
        if (strlen($line) > 1) {
          $value   = trim(substr($line,1));
          // Set the type of the value.  Int, string, etc
          $value   = $this->_toType($value);
          $array[] = $value;
        } else {
          $array[] = array();
        }
      } elseif (preg_match('/^(.+):/',$line,$key)) {
        // It's a key/value pair most likely
        // If the key is in double quotes pull it out
        if (preg_match('/^(["\'](.*)["\'](\s)*:)/',$line,$matches)) {
          $value = trim(str_replace($matches[1],'',$line));
          $key   = $matches[2];
        } else {
          // Do some guesswork as to the key and the value
          $explode = explode(':',$line);
          $key     = trim($explode[0]);
          array_shift($explode);
          $value   = trim(implode(':',$explode));
        }

        // Set the type of the value.  Int, string, etc
        $value = $this->_toType($value);
        if (empty($key)) {
          $array[]     = $value;
        } else {
          $array[$key] = $value;
        }
      }
      return $array;
    }

    /**
     * Finds the type of the passed value, returns the value as the new type.
     * @access private
     * @param string $value
     * @return mixed
     */
    function _toType($value) {
      if (preg_match('/^("(.*)"|\'(.*)\')/',$value,$matches)) {
       $value = (string)preg_replace('/(\'\'|\\\\\')/',"'",end($matches));
       $value = preg_replace('/\\\\"/','"',$value);
      } elseif (preg_match('/^\\[(.+)\\]$/',$value,$matches)) {
        // Inline Sequence

        // Take out strings sequences and mappings
        $explode = $this->_inlineEscape($matches[1]);

        // Propogate value array
        $value  = array();
        foreach ($explode as $v) {
          $value[] = $this->_toType($v);
        }
      } elseif (strpos($value,': ')!==false && !preg_match('/^{(.+)/',$value)) {
          // It's a map
          $array = explode(': ',$value);
          $key   = trim($array[0]);
          array_shift($array);
          $value = trim(implode(': ',$array));
          $value = $this->_toType($value);
          $value = array($key => $value);
      } elseif (preg_match("/{(.+)}$/",$value,$matches)) {
        // Inline Mapping

        // Take out strings sequences and mappings
        $explode = $this->_inlineEscape($matches[1]);

        // Propogate value array
        $array = array();
        foreach ($explode as $v) {
          $array = $array + $this->_toType($v);
        }
        $value = $array;
      } elseif (strtolower($value) == 'null' or $value == '' or $value == '~') {
        $value = NULL;
      } elseif (preg_match ('/^[0-9]+$/', $value)) {
      // Cheeky change for compartibility with PHP < 4.2.0
        $value = (int)$value;
      } elseif (in_array(strtolower($value),
                  array('true', 'on', '+', 'yes', 'y'))) {
        $value = true;
      } elseif (in_array(strtolower($value),
                  array('false', 'off', '-', 'no', 'n'))) {
        $value = false;
      } elseif (is_numeric($value)) {
        $value = (float)$value;
      } else {
        // Just a normal string, right?
        $value = trim(preg_replace('/#(.+)$/','',$value));
      }

      return $value;
    }

    /**
     * Used in inlines to check for more inlines or quoted strings
     * @access private
     * @return array
     */
    function _inlineEscape($inline) {
      // There's gotta be a cleaner way to do this...
      // While pure sequences seem to be nesting just fine,
      // pure mappings and mappings with sequences inside can't go very
      // deep.  This needs to be fixed.

      $saved_strings = array();

      // Check for strings
      $regex = '/(?:(")|(?:\'))((?(1)[^"]+|[^\']+))(?(1)"|\')/';
      if (preg_match_all($regex,$inline,$strings)) {
        $saved_strings = $strings[0];
        $inline  = preg_replace($regex,'YAMLString',$inline);
      }
      unset($regex);

      // Check for sequences
      if (preg_match_all('/\[(.+)\]/U',$inline,$seqs)) {
        $inline = preg_replace('/\[(.+)\]/U','YAMLSeq',$inline);
        $seqs   = $seqs[0];
      }

      // Check for mappings
      if (preg_match_all('/{(.+)}/U',$inline,$maps)) {
        $inline = preg_replace('/{(.+)}/U','YAMLMap',$inline);
        $maps   = $maps[0];
      }

      $explode = explode(', ',$inline);


      // Re-add the sequences
      if (!empty($seqs)) {
        $i = 0;
        foreach ($explode as $key => $value) {
          if (strpos($value,'YAMLSeq') !== false) {
            $explode[$key] = str_replace('YAMLSeq',$seqs[$i],$value);
            ++$i;
          }
        }
      }

      // Re-add the mappings
      if (!empty($maps)) {
        $i = 0;
        foreach ($explode as $key => $value) {
          if (strpos($value,'YAMLMap') !== false) {
            $explode[$key] = str_replace('YAMLMap',$maps[$i],$value);
            ++$i;
          }
        }
      }

      // Re-add the strings
      if (!empty($saved_strings)) {
        $i = 0;
        foreach ($explode as $key => $value) {
          while (strpos($value,'YAMLString') !== false) {
            $explode[$key] = preg_replace('/YAMLString/',$saved_strings[$i],$value, 1);
            ++$i;
            $value = $explode[$key];
          }
        }
      }

      return $explode;
    }

    /**
     * Builds the PHP array from all the YAML nodes we've gathered
     * @access private
     * @return array
     */
    function _buildArray() {
      $trunk = array();

      if (!isset($this->_indentSort[0])) {
        return $trunk;
      }

      foreach ($this->_indentSort[0] as $n) {
        if (empty($n->parent)) {
          $this->_nodeArrayizeData($n);
          // Check for references and copy the needed data to complete them.
          $this->_makeReferences($n);
          // Merge our data with the big array we're building
          $trunk = $this->_array_kmerge($trunk,$n->data);
        }
      }

      return $trunk;
    }

    /**
     * Traverses node-space and sets references (& and *) accordingly
     * @access private
     * @return bool
     */
    function _linkReferences() {
      if (is_array($this->_haveRefs)) {
        foreach ($this->_haveRefs as $node) {
          if (!empty($node->data)) {
            $key = key($node->data);
            // If it's an array, don't check.
            if (is_array($node->data[$key])) {
              foreach ($node->data[$key] as $k => $v) {
                $this->_linkRef($node,$key,$k,$v);
              }
            } else {
              $this->_linkRef($node,$key);
            }
          }
        }
      }
      return true;
    }

    function _linkRef(&$n,$key,$k = NULL,$v = NULL) {
      if (empty($k) && empty($v)) {
        // Look for &refs
        if (preg_match('/^&([^ ]+)/',$n->data[$key],$matches)) {
          // Flag the node so we know it's a reference
          $this->_allNodes[$n->id]->ref = substr($matches[0],1);
          $this->_allNodes[$n->id]->data[$key] =
                   substr($n->data[$key],strlen($matches[0])+1);
        // Look for *refs
        } elseif (preg_match('/^\*([^ ]+)/',$n->data[$key],$matches)) {
          $ref = substr($matches[0],1);
          // Flag the node as having a reference
          $this->_allNodes[$n->id]->refKey =  $ref;
        }
      } elseif (!empty($k) && !empty($v)) {
        if (preg_match('/^&([^ ]+)/',$v,$matches)) {
          // Flag the node so we know it's a reference
          $this->_allNodes[$n->id]->ref = substr($matches[0],1);
          $this->_allNodes[$n->id]->data[$key][$k] =
                              substr($v,strlen($matches[0])+1);
        // Look for *refs
        } elseif (preg_match('/^\*([^ ]+)/',$v,$matches)) {
          $ref = substr($matches[0],1);
          // Flag the node as having a reference
          $this->_allNodes[$n->id]->refKey =  $ref;
        }
      }
    }

    /**
     * Finds the children of a node and aids in the building of the PHP array
     * @access private
     * @param int $nid The id of the node whose children we're gathering
     * @return array
     */
    function _gatherChildren($nid) {
      $return = array();
      $node   =& $this->_allNodes[$nid];
      if (is_array ($this->_allParent[$node->id])) {
        foreach ($this->_allParent[$node->id] as $nodeZ) {
          $z =& $this->_allNodes[$nodeZ];
          // We found a child
          $this->_nodeArrayizeData($z);
          // Check for references
          $this->_makeReferences($z);
          // Merge with the big array we're returning
          // The big array being all the data of the children of our parent node
          $return = $this->_array_kmerge($return,$z->data);
        }
      }
      return $return;
    }

    /**
     * Turns a node's data and its children's data into a PHP array
     *
     * @access private
     * @param array $node The node which you want to arrayize
     * @return boolean
     */
    function _nodeArrayizeData(&$node) {
      if (is_array($node->data) && $node->children == true) {
        // This node has children, so we need to find them
        $childs = $this->_gatherChildren($node->id);
        // We've gathered all our children's data and are ready to use it
        $key = key($node->data);
        $key = empty($key) ? 0 : $key;
        // If it's an array, add to it of course
        if (isset ($node->data[$key])) {
            if (is_array($node->data[$key])) {
              $node->data[$key] = $this->_array_kmerge($node->data[$key],$childs);
            } else {
              $node->data[$key] = $childs;
            }
        } else {
            $node->data[$key] = $childs;
        }
      } elseif (!is_array($node->data) && $node->children == true) {
        // Same as above, find the children of this node
        $childs       = $this->_gatherChildren($node->id);
        $node->data   = array();
        $node->data[] = $childs;
      }

      // We edited $node by reference, so just return true
      return true;
    }

    /**
     * Traverses node-space and copies references to / from this object.
     * @access private
     * @param object $z A node whose references we wish to make real
     * @return bool
     */
    function _makeReferences(&$z) {
      // It is a reference
      if (isset($z->ref)) {
        $key                = key($z->data);
        // Copy the data to this object for easy retrieval later
        $this->ref[$z->ref] =& $z->data[$key];
      // It has a reference
      } elseif (isset($z->refKey)) {
        if (isset($this->ref[$z->refKey])) {
          $key           = key($z->data);
          // Copy the data from this object to make the node a real reference
          $z->data[$key] =& $this->ref[$z->refKey];
        }
      }
      return true;
    }


    /**
     * Merges arrays and maintains numeric keys.
     *
     * An ever-so-slightly modified version of the array_kmerge() function posted
     * to php.net by mail at nospam dot iaindooley dot com on 2004-04-08.
     *
     * http://us3.php.net/manual/en/function.array-merge.php#41394
     *
     * @access private
     * @param array $arr1
     * @param array $arr2
     * @return array
     */
    function _array_kmerge($arr1,$arr2) {
      if(!is_array($arr1)) $arr1 = array();
      if(!is_array($arr2)) $arr2 = array();

      $keys  = array_merge(array_keys($arr1),array_keys($arr2));
      $vals  = array_merge(array_values($arr1),array_values($arr2));
      $ret   = array();
      foreach($keys as $key) {
        list($unused,$val) = each($vals);
        if (isset($ret[$key]) and is_int($key)) $ret[] = $val; else $ret[$key] = $val;
      }
      return $ret;
    }
  }


?>