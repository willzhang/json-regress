///|
fn decode_pointer(pointer : String) -> Array[String] raise InvalidInput {
  if pointer == "" {
    return []
  }
  if !pointer.has_prefix("/") {
    raise InvalidInput("JSON Pointer must be empty or start with /")
  }
  let tokens = []
  for raw in pointer.split("/").drop(1) {
    let chars = raw.to_owned().iter().to_array()
    let token = StringBuilder()
    let mut i = 0
    while i < chars.length() {
      if chars[i] == '~' {
        if i + 1 >= chars.length() {
          raise InvalidInput("incomplete JSON Pointer escape")
        }
        match chars[i + 1] {
          '0' => token.write_char('~')
          '1' => token.write_char('/')
          _ => raise InvalidInput("invalid JSON Pointer escape")
        }
        i = i + 2
      } else {
        token.write_char(chars[i])
        i = i + 1
      }
    }
    tokens.push(token.to_string())
  }
  if tokens.length() > 128 {
    raise InvalidInput("JSON Pointer exceeds 128 segments")
  }
  tokens
}

///|
fn array_index(token : String, length : Int) -> Int raise InvalidInput {
  if token == "" || (token.length() > 1 && token.has_prefix("0")) {
    raise InvalidInput("array index must be canonical decimal")
  }
  let mut index = 0
  for char in token {
    if char < '0' || char > '9' {
      raise InvalidInput("array index must be canonical decimal")
    }
    let digit = char.to_int() - '0'.to_int()
    if index > (2147483647 - digit) / 10 {
      raise InvalidInput("array index overflows Int")
    }
    index = index * 10 + digit
  }
  if index >= length {
    raise InvalidInput("array index out of bounds")
  }
  index
}

///|
fn json_number(value : Json) -> Double raise InvalidInput {
  match value {
    Number(n, repr~) => {
      if n == 0.0 {
        if repr is Some(text) {
          for char in text {
            if char == 'e' || char == 'E' {
              break
            }
            if char >= '1' && char <= '9' {
              raise InvalidInput("preserved JSON number underflow")
            }
          }
        }
      }
      if n.is_nan() || n.is_inf() || n.abs() >= 9007199254740992.0 {
        raise InvalidInput("unsupported JSON numeric value")
      }
      n
    }
    _ => raise InvalidInput("expected a JSON number")
  }
}

///|
/// Select an exact RFC 6901 pointer and read {shape, dtype, data}.
/// Extra object fields are permitted; shape/data must be flat arrays.
pub fn Tensor::from_json(
  document : Json,
  pointer? : String = "",
) -> Tensor raise InvalidInput {
  let tokens = decode_pointer(pointer)
  let mut selected = document
  for token in tokens {
    selected = match selected {
      Object(fields) =>
        match fields.get(token) {
          Some(value) => value
          None =>
            raise InvalidInput("missing object member at pointer \{pointer}")
        }
      Array(items) => items[array_index(token, items.length())]
      _ => raise InvalidInput("cannot traverse scalar at pointer \{pointer}")
    }
  }
  let fields = match selected {
    Object(fields) => fields
    _ =>
      raise InvalidInput("tensor must be a JSON object at pointer \{pointer}")
  }
  let dims = match fields.get("shape") {
    Some(Array(dims)) => dims
    _ => raise InvalidInput("tensor shape must be an array")
  }
  let shape = []
  for dim in dims {
    let n = json_number(dim)
    if n < 0.0 || n > 2147483647.0 || n.floor() != n {
      raise InvalidInput("shape dimensions must be non-negative Int values")
    }
    shape.push(n.to_int())
  }
  let dtype = match fields.get("dtype") {
    Some(String(label)) => label
    _ => raise InvalidInput("tensor dtype must be a string")
  }
  let values = match fields.get("data") {
    Some(Array(values)) => values
    _ => raise InvalidInput("tensor data must be an array")
  }
  let data = values.map(json_number)
  Tensor::new(shape, dtype, data)
}

///|
pub fn Tensor::to_json(self : Tensor) -> Json {
  { "shape": self.shape, "dtype": self.dtype, "data": self.data }
}
