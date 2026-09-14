///|
/// Validated row-major numeric data. Construction and access copy arrays.
pub struct Tensor {
  shape : Array[Int]
  dtype : String
  data : Array[Double]
} derive(Debug)

///|
pub suberror InvalidInput {
  InvalidInput(String)
} derive(Debug)

///|
/// Scalar shape [] requires one value; a zero axis requires empty data.
pub fn Tensor::new(
  shape : Array[Int],
  dtype : String,
  data : Array[Double],
) -> Tensor raise InvalidInput {
  if dtype == "" {
    raise InvalidInput("dtype must be a non-empty source type label")
  }
  let mut empty = false
  for dim in shape {
    if dim < 0 {
      raise InvalidInput("shape dimensions must be non-negative")
    }
    if dim == 0 {
      empty = true
    }
  }
  let mut count = if empty { 0 } else { 1 }
  if !empty {
    for dim in shape {
      if count > 2147483647 / dim {
        raise InvalidInput("shape product exceeds Int capacity")
      }
      count = count * dim
    }
  }
  if data.length() != count {
    raise InvalidInput("shape requires \{count} values; got \{data.length()}")
  }
  for i, value in data {
    if value.is_nan() || value.is_inf() || value.abs() >= 9007199254740992.0 {
      raise InvalidInput("unsupported numeric value at flat index \{i}")
    }
  }
  { shape: shape.copy(), dtype, data: data.copy(), }
}

///|
pub fn Tensor::shape(self : Tensor) -> Array[Int] {
  self.shape.copy()
}

///|
pub fn Tensor::dtype(self : Tensor) -> String {
  self.dtype
}

///|
pub fn Tensor::data(self : Tensor) -> Array[Double] {
  self.data.copy()
}

///|
pub fn Tensor::size(self : Tensor) -> Int {
  self.data.length()
}
