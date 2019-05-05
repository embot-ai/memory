<?php
class Memory {
	public static function set($sid, $key, $val) {
		@file_get_contents('http://localhost:9999/set?sid='.urlencode($sid).'&key='.urlencode($key).'&val='.urlencode($val));
	}

	public static function get($sid, $key, $default=NULL) {
		$val = @file_get_contents('http://localhost:9999/get?sid='.urlencode($sid).'&key='.urlencode($key));
		if ($val == "undefined") {
			return $default;
		}
		return $val;
	}

	public static function setArray($sid, $key, $arr) {
		$val = json_encode($arr);
		@file_get_contents('http://localhost:9999/set?sid='.urlencode($sid).'&key='.urlencode($key).'&val='.urlencode($val));
	}

	public static function getArray($sid, $key, $default=NULL) {
		$val = @file_get_contents('http://localhost:9999/get?sid='.urlencode($sid).'&key='.urlencode($key));
		if ($val == "undefined") {
			return $default;
		}
		return json_decode($val, TRUE);
		//return $val;
	}

	public static function getDelete($sid, $key, $default=NULL) {
		$val = @file_get_contents('http://localhost:9999/get?sid='.urlencode($sid).'&key='.urlencode($key).'&once=true');
		if ($val == "undefined") {
			return $default;
		}
		return $val;
	}

	public static function json($sid) {
		return @json_decode(file_get_contents('http://localhost:9999/json?sid='.urlencode($sid)), true);
	}

	public static function delete($sid, $key) {
		@file_get_contents('http://localhost:9999/delete?sid='.urlencode($sid).'&key='.urlencode($key));
	}

	public static function incr($sid, $key) {
		return @file_get_contents('http://localhost:9999/incr?sid='.urlencode($sid).'&key='.urlencode($key));
	}

	public static function reset($sid) {
		@file_get_contents('http://localhost:9999/reset?sid='.urlencode($sid));
	}

	public static function setMany($sid, $arr) {
		self::setManyJSON($sid, $arr);
		/* $query = array('sid' => $sid);
		$i = 1;
		foreach ($arr as $key => $val) {
			$query['key' . $i] = $key;
			$query['val' . $i] = $val;
			$i++;
		}
		@file_get_contents('http://localhost:9999/setMany?'.http_build_query($query)); */
	}

	public static function setManyJSON($sid, $arr) {
		$query = array('sid' => $sid);
		$i = 1;
		foreach ($arr as $key => $val) {
			$query['key' . $i] = $key;
			$query['val' . $i] = $val;
			$i++;
		}
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, "http://localhost:9999/setManyJSON");
		curl_setopt($ch, CURLOPT_POST, 1);
		curl_setopt($ch, CURLOPT_HEADER, 0);
		curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($query));
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		$server_output = curl_exec($ch);
		curl_close($ch);
		//var_dump($server_output);
	}
}
