<?php

if (is_array($argv) && count($argv)>6) {
    $dbhost=$argv[1];
    $dbport=$argv[2];
    $database=$argv[3];
    $user=$argv[4];
    $password=$argv[5];
    $path=$argv[6];
}
else {
    echo "Usage php mpDBBackup.php <dbhost> <port> <database> <user> <password> <path for dump file>\n";
    exit;
}

error_reporting(E_ERROR | E_PARSE);

//date_default_timezone_set('UTC');
$dumpDTS = date("YmdHis");
$dumpFileName = "mpDump_{$dumpDTS}.sql";
$dumpPath = "$path/$dumpFileName";

$link = mysql_connect($dbhost, $user, $password);
if (!$link) {
    die('Could not connect: ' . mysql_error());
}

$source = mysql_select_db('$database', $link);
$sql = "SHOW FULL TABLES IN `$database` WHERE TABLE_TYPE LIKE 'VIEW';";
$result = mysql_query($sql);

if (!$result) {
    echo 'Could not run query: ' . mysql_error();
    exit;
}

$views=array();
while ($row = mysql_fetch_row($result)) {
   $views[]="--ignore-table={$database}.".$row[0];
}

$myCMD = "mysqldump -h $dbhost -u $user --password=\"$password\" $database ".implode(" ",$views);
exec($myCMD . " > $dumpPath");

?>