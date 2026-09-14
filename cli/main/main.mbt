///|
suberror Usage {
  Usage(String)
} derive(Debug)

///|
fn usage() -> String {
  "Usage: json-regress compare EXPECTED ACTUAL RULES [--format text|json] [--report NEW_FILE] [--repro NEW_FILE]\n       json-regress replay REPRO_FILE [--format text|json] [--report NEW_FILE]\nExit: 0 match, 1 mismatch, 2 error. Output files must not already exist."
}

///|
fn write_new(path : String, text : String) -> Unit raise {
  if @fs.path_exists(path) {
    raise Usage("refusing to overwrite existing output: \{path}")
  }
  @fs.write_string_to_file(path, text + "\n")
}

///|
fn run(args : Array[String]) -> Int {
  let mut format = "text"
  // Choose JSON error output even when earlier positional arguments are invalid.
  for i in 0..<(args.length() - 1) {
    if args[i] == "--format" && args[i + 1] == "json" {
      format = "json"
    }
  }
  let result = try {
    if args.length() == 0 {
      raise Usage(usage())
    }
    let command = args[0]
    let positional = if command == "compare" {
      4
    } else if command == "replay" {
      2
    } else {
      raise Usage(usage())
    }
    if args.length() < positional {
      raise Usage(usage())
    }
    let flags : Map[String, String] = Map([])
    let mut i = positional
    while i < args.length() {
      let flag = args[i]
      if !["--format", "--report", "--repro"].contains(flag) ||
        i + 1 >= args.length() {
        raise Usage("unknown option or missing value: \{flag}")
      }
      if flags.contains(flag) {
        raise Usage("duplicate option: \{flag}")
      }
      flags[flag] = args[i + 1]
      i = i + 2
    }
    format = flags.get("--format").unwrap_or("text")
    if format != "text" && format != "json" {
      raise Usage("--format must be text or json")
    }
    if command == "replay" && flags.contains("--repro") {
      raise Usage("replay does not accept --repro")
    }
    for flag in ["--report", "--repro"] {
      if flags.get(flag) is Some(path) {
        if path == "" || @fs.path_exists(path) {
          raise Usage("output must be a new file: \{path}")
        }
      }
    }
    if flags.get("--report") is Some(path) {
      if flags.get("--repro") == Some(path) {
        raise Usage("report and repro paths must differ")
      }
    }
    let report = if command == "replay" {
      @checking.replay_text(@fs.read_file_to_string(args[1]))
    } else {
      let expected = @fs.read_file_to_string(args[1])
      let actual = @fs.read_file_to_string(args[2])
      let rules = @fs.read_file_to_string(args[3])
      let report = @checking.compare_text(expected, actual, rules)
      if report.exit_code() != 0 {
        if flags.get("--repro") is Some(path) {
          let replay = @checking.replay_document(
            expected,
            actual,
            rules,
            report,
            {
              "expected_file": args[1],
              "actual_file": args[2],
              "rules_file": args[3],
            },
          )
          write_new(path, @checking.canonical_json(replay))
        }
      }
      report
    }
    if flags.get("--report") is Some(path) {
      write_new(path, @checking.canonical_json(report.to_json()))
    }
    report
  } catch {
    Usage(message) => @checking.error_report("usage_error", message)
    @fs.IOError(message) => @checking.error_report("io_error", message)
    _ => @checking.error_report("io_error", "file operation failed")
  }
  println(
    if format == "json" {
      @checking.canonical_json(result.to_json())
    } else {
      result.format()
    },
  )
  result.exit_code()
}

///|
fn main {
  let args = @env.args().iter().drop(1).to_array()
  if args == ["--help"] || args == ["-h"] {
    println(usage())
  } else {
    @sys.exit(run(args))
  }
}
