class List<T> {
  ghost var Contents: seq<T>;
  ghost var Repr: set<object>;

  var a: array<T>;
  var n: nat;

  predicate Valid()
    reads this, Repr;
  {
    this in Repr && null !in Repr &&
    a in Repr &&
    n <= a.Length != 0 &&
    Contents == a[..n]
  }

  constructor Init()
    modifies this;
    ensures Valid() && fresh(Repr - {this});
    ensures Contents == [];
  {
    Contents, Repr, n := [], {this}, 0;
    a := new T[25];
    Repr := Repr + {a};
  }

  method Add(t: T)
    requires Valid();
    modifies Repr;
    ensures Valid() && fresh(Repr - old(Repr));
    ensures Contents == old(Contents) + [t];
  {
    if (n == a.Length) {
      var b := new T[2 * a.Length];
      parallel (i | 0 <= i < a.Length) {
        b[i] := a[i];
      }
      assert b[..n] == a[..n] == Contents;
      a, Repr := b, Repr + {b};
      assert b[..n] == Contents;
    }
    a[n], n, Contents := t, n + 1, Contents + [t];
  }
}

class Cell { var data: int; }

iterator M<T>(l: List<T>, c: Cell) yields (x: T)
  requires l != null && l.Valid() && c != null;
  reads l.Repr;
  modifies c;
  yield requires true;
  yield ensures xs <= l.Contents;  // this is needed in order for the next line to be well-formed
  yield ensures x == l.Contents[|xs|-1];
  ensures xs == l.Contents;
{
  var i := 0;
  while (i < l.n)
    invariant i <= l.n && i == |xs| && xs <= l.Contents;
  {
    if (*) { assert l.Valid(); }  // this property is maintained, due to the reads clause
    if (*) {
      x := l.a[i]; yield;  // or, equivalently, 'yield l.a[i]'
      i := i + 1;
    } else {
      x, i := l.a[i], i + 1;
      yield;
    }
  }
}

method Client<T(==)>(l: List, stop: T) returns (s: seq<T>)
  requires l != null && l.Valid();
{
  var c := new Cell;
  var iter := new M.M(l, c);
  s := [];
  while (true)
    invariant iter.Valid() && fresh(iter._new);
    invariant iter.xs <= l.Contents;
    decreases |l.Contents| - |iter.xs|;
  {
    var more := iter.MoveNext();
    if (!more) { break; }
    s := s + [iter.x];
    if (iter.x == stop) { return; }  // if we ever see 'stop', then just end
  }
}

method PrintSequence<T>(s: seq<T>)
{
  var i := 0;
  while (i < |s|)
  {
    print s[i], " ";
    i := i + 1;
  }
  print "\n";
}

method Main()
{
  var myList := new List.Init();
  var i := 0;
  while (i < 100)
    invariant myList.Valid() && fresh(myList.Repr);
  {
    myList.Add(i);
    i := i + 2;
  }
  var s := Client(myList, 89);
  PrintSequence(s);
  s := Client(myList, 14);
  PrintSequence(s);
}
