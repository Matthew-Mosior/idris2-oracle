# Idris2 bindings to the Oracle ODPI-C API

This library provides a modern Oracle Database client library for Idris2 built on top of Oracle's [ODPI-C API](https://github.com/oracle/odpi). It combines a low-level FFI with a high-level, type-safe API supporting prepared statements, transactions, typed row decoding, LOBs, and Oracle-native data types, allowing Idris2 applications to interact with Oracle databases safely and efficiently.

> [!NOTE]
> The internals of this library heavily utilize the [idris2-ref1](https://github.com/stefan-hoeck/idris2-ref1), [idris2-elin](https://github.com/stefan-hoeck/idris2-elin) and [idris2-json](https://github.com/stefan-hoeck/idris2-json/tree/main) libraries, so you may want to familiarize yourself with them first.

## Building

Running `make build` builds the library (this can also be done via `pack build`).

## Installation

This library depends on Oracle’s ODPI-C layer, and ODPI-C in turn requires Oracle Client libraries at runtime.
Oracle’s documentation states that these libraries can come from Oracle Instant Client, an Oracle Database installation, or a full Oracle Client installation. ODPI-C also loads the client library dynamically at runtime, so the application must be able to locate the Oracle Client shared libraries when it starts.

Running `make install` installs the library.

## Features

- **Complete Oracle connectivity**
  - Connect and disconnect from Oracle databases
  - Transaction management
  - Automatic cleanup of database resources
- **Prepared statements**
  - Prepare SQL once and execute multiple times
  - Named parameter binding
  - Automatic statement lifetime management
  - Statement reuse
- **Rich type support**
  - `VARCHAR2`
  - `NUMBER`
  - `BOOLEAN`
  - `CLOB`
  - `BLOB`
  - `TIMESTAMP`
  - `TIMESTAMP WITH TIME ZONE`
  - `INTERVAL YEAR TO MONTH`
  - `INTERVAL DAY TO SECOND`
  - `JSON` (via `idris2-json`)
- **Typed decoding**
  - Automatic conversion from Oracle values to Idris types via `FromOracle`
  - Automatic row decoding via `FromRow`
  - Typed query APIs returning user-defined records
- **Type-safe parameter encoding**
  - Automatic conversion to Oracle bind values via `ToOracle`
  - Record encoding through `ToRow`
- **LOB support**
  - Read and write `CLOB`
  - Read and write `BLOB`
  - Automatic LOB resource management
- **Transaction support**
  - Commit
  - Rollback
- **Error handling**
  - Oracle errors are represented as ordinary Idris values
  - Rich diagnostic information
- **Resource safety**
  - Automatic release of
    - statements
    - query metadata
    - temporary buffers
    - LOB handles
  - Bracket-style APIs throughout (via `idris2-elin`)
- **High-level query interface**
  - Raw queries returning `OracleValue`
  - Typed queries returning Idris records
  - Single-row queries
  - Exactly-one-row queries
- **Comprehensive test suite**
  - Connection tests
  - Statement tests
  - Parameter binding tests
  - Query tests
  - Typed decoding tests
  - Transaction tests

## Why use this library?

Most Oracle client libraries fall into one of two categories:

- Thin C bindings that expose Oracle's underlying APIs almost directly. While these provide maximum flexibility, they also require callers to manually manage statements, buffers, LOB locators, and other native resources. Small mistakes can easily lead to memory leaks or invalid resource usage.
- Heavyweight object-relational frameworks that hide much of Oracle's functionality behind large abstraction layers. These often sacrifice transparency, make advanced Oracle features difficult to access, and provide little static verification of application logic.

This library aims for a middle ground between the aforementioned categories.
It exposes Oracle's capabilities through a small, composable API while using Idris2's type system to eliminate many classes of runtime errors. Resources are managed automatically, database values are represented explicitly, and query results can be decoded directly into ordinary Idris records without reflection or runtime code generation.

Since the library is built directly on Oracle's officially supported ODPI-C layer, it also inherits the portability, performance, and compatibility of Oracle's native client implementation while presenting a purely functional Idris2 interface.

## Architecture

```mermaid
flowchart LR

A[Idris Application]
    --> B[idris2-oracle]

B
    --> C[High-level API]

B
    --> D[FFI Layer]

D
    --> E[ODPI-C]

E
    --> F[Oracle Client]

F
    --> G[(Oracle Database)]
```

This library is built as a small Idris2 layer on top of Oracle’s ODPI-C library. ODPI-C provides the low-level bridge to Oracle Client libraries and the database itself, while this library adds a type-safe Idris2 API for connections, statements, transactions, parameter binding, row decoding, and LOB handling.

At the highest level, applications work with ordinary Idris2 values and records. Those values are translated into `OracleValue`s and bind parameters, and query results are translated back through `FromOracle` and `FromRow` instances.

A typical query therefore flows through the library like this:

```mermaid
sequenceDiagram

participant User
participant Query
participant Statement
participant Oracle

User->>Query: query_
Query->>Statement: prepare
Statement->>Oracle: dpiConn_prepareStmt

Query->>Statement: bind

Statement->>Oracle: dpiStmt_bindByName

Query->>Statement: execute

Statement->>Oracle: dpiStmt_execute

loop Fetch rows
Statement->>Oracle: dpiStmt_fetch
Statement->>Oracle: dpiStmt_getQueryValue
end

Statement->>Oracle: dpiStmt_release

Query-->>User: List a
```

## Connecting to Oracle

The recommended way to establish a connection is with `withConnection`.

`withConnection` automatically opens the connection before executing your action and guarantees that the connection is released afterwards, even if an error occurs. This mirrors the rest of the library's resource-management philosophy and should be preferred over calling `connect` and `disconnect` manually.

```mermaid
flowchart LR

A[ConnectInfo]

-->

B[withConnection]

-->

C[Open Connection]

-->

D[Execute User Action]

-->

E[Automatically Disconnect]

```

A typical application begins by constructing a `ConnectInfo` value.

```idris
connectInfo : ConnectInfo
connectInfo =
  MkConnectInfo
    "idris"
    "password"
    "localhost"
    1521
    "FREEPDB1"
```

A connection can then be used like this:

```idris
main : IO ()
main =
  withConnection connectInfo $ \conn => do
    putStrLn "Successfully connected!"
```

Notice that the connection is never explicitly closed. Once the supplied function returns, `withConnection` automatically disconnects from Oracle.

### Why use `withConnection`?

Every connection to Oracle consumes database and client resources.

If a program exits early because of an exception or returns from multiple branches, manually calling `disconnect` becomes easy to forget.

Using `withConnection` avoids these problems entirely.

```mermaid
flowchart TD

A[withConnection]

-->

B[Open Oracle Connection]

-->

C[Run User Code]

-->

D[Disconnect]

C -->|Exception| D
C -->|Normal Return| D

```

For this reason, nearly every example in this tutorial uses `withConnection`.

### Manual connections

Advanced applications may wish to manage connection lifetimes manually.

For those situations the lower-level API is available:

```idris
result <- connect connectInfo

case result of
  Left err =>
    putStrLn (show err)

  Right conn => do
    ...
    disconnect conn
```

This is occasionally useful for long-running services, but most applications should prefer `withConnection`.

## Executing SQL

Once connected, SQL statements can be executed with `execute_`.

`execute_` is intended for SQL that does not return rows, including:

- `CREATE TABLE`
- `CREATE INDEX`
- `INSERT`
- `UPDATE`
- `DELETE`
- `ALTER`
- `DROP`

For example:

```idris
withConnection connectInfo $ \conn =>
  execute_
    conn
    """
    CREATE TABLE people
    (
        id NUMBER PRIMARY KEY,
        name VARCHAR2(100)
    )
    """
    []
```

Every execution returns:

```idris
Either OracleError ()
```

Most database operations therefore follow the pattern:

```idris
result <-
  execute_
    conn
    sql
    params

case result of
  Left err =>
    ...

  Right () =>
    ...
```

## Prepared Statements

Although `execute_` is convenient, Oracle performs best when SQL statements are prepared once and reused.

This library exposes prepared statements through the `Statement` type.

Like `withConnection`, `withStatement` (the recommended way to create a statement) automatically manages the lifetime of the underlying Oracle resource.

```mermaid
flowchart LR

A[SQL]

-->

B[withStatement]

-->

C[Prepare]

-->

D[User Action]

-->

E[Release Statement]

```

A prepared statement looks like this:

```idris
withStatement conn
  """
  INSERT INTO people(name, age)
  VALUES(:name, :age)
  """
  $ \stmt => do

    ...
```

When the callback returns, the prepared statement is automatically released.

Even if an exception occurs while executing the statement, Oracle resources are still cleaned up correctly.

### Why `withStatement`?

Oracle statements are native resources allocated by ODPI-C.

Forgetting to release them can leak memory and database handles.

Using `withStatement` guarantees that every prepared statement has a matching release.

This is the same design philosophy used throughout the library:

- `withConnection`
- `withStatement`
- `withQueryInfo`

Each acquires a resource, executes user code, and guarantees cleanup.

## Bind Parameters

Rather than constructing SQL strings manually, applications should bind values through named parameters.

Binding provides several advantages:

- avoids SQL injection
- improves statement reuse
- avoids manual quoting
- allows Oracle to optimize execution

A bind parameter consists of a parameter name and an `OracleValue`.

For example:

```idris
MkBindParameter
  ":name"
  (OracleString "Alice")
```

Multiple parameters are simply collected into a list:

```idris
[
  MkBindParameter
    ":name"
    (OracleString "Alice")

, MkBindParameter
    ":age"
    (OracleNumber 30)
]
```

These correspond to placeholders inside the SQL statement.

```sql
INSERT INTO people
(
    name,
    age
)
VALUES
(
    :name,
    :age
)
```

The library automatically binds each parameter before executing the statement.

### Supported bind types

The library currently supports binding:

- `OracleNull`
- `OracleString`
- `OracleNumber`
- `OracleBool`
- `OracleClob`
- `OracleBlob`
- `OracleTimestamp`
- `OracleTimestampTZ`
- `OracleIntervalYM`
- `OracleIntervalDS`

Additional Oracle types will be added over time as support is implemented.

### Encoding user types

Applications rarely need to construct `BindParameter` values manually.

Instead, user-defined records can implement the `ToRow` interface.

```idris
implementation ToRow Person where
  toRow person =
    [
      MkBindParameter
        ":name"
        (OracleString person.name)

    , MkBindParameter
        ":age"
        (OracleNumber person.age)
    ]
```

Once a `ToRow` instance exists, records can be converted into bind parameters automatically, allowing the application's domain model to remain independent of Oracle-specific types.

## Transactions

```mermaid
stateDiagram-v2

[*] --> Open

Open --> Active

Active --> Commit

Active --> Rollback

Commit --> Open

Rollback --> Open
```

Oracle transactions are controlled explicitly through the `Connection`.

The library exposes the two standard transaction operations:

- `commit`
- `rollback`

A typical transaction looks like

```idris
execute_ conn insertPerson alice
>>== \_ =>
execute_ conn insertPerson bob
>>== \_ =>
commit conn
```

If an error occurs before the final commit,

```idris
rollback conn
```

returns the database to its previous state.

## Why explicit transactions?

Grouping several statements into one transaction provides:

- atomicity
- consistency
- isolation
- durability

Transactions also reduces unnecessary commits, and is almost always preferable to committing after every statement.

## Working with LOBs

Oracle supports two large-object types:

- `CLOB`
- `BLOB`

These are represented as

```idris
OracleClob String
OracleBlob ByteString
```

Unlike ordinary strings and byte arrays, Oracle stores LOBs through dedicated LOB locators.

Reading a BLOB produces

```idris
OracleBlob bytes
```

Reading a CLOB produces

```idris
OracleClob text
```

Internally the library acquires the LOB locator, reads its contents, releases temporary buffers, and returns ordinary Idris values.

## LOB pipeline

```mermaid
flowchart LR

A[Oracle LOB]

-->

B[dpiLob]

-->

C[Read]

-->

D[OracleBlob / OracleClob]

-->

E[FromOracle]

-->

F[Application]

```

Applications therefore never manipulate native LOB handles directly.

## Dates, Times, and Intervals

Oracle provides several temporal datatypes.

The library currently supports:

| Oracle datatype            |  Idris representation |
| -------------------------- | --------------------- |
| `TIMESTAMP`                |  `OracleTimestamp`    |
| `TIMESTAMP WITH TIME ZONE` | `OracleTimestampTZ`   |
| `INTERVAL YEAR TO MONTH`   | `OracleIntervalYM`    |
| `INTERVAL DAY TO SECOND`   | `OracleIntervalDS`    |

For example,

```idris
MkOracleTimestamp
    2025
    7
    10
    14
    30
    15
    123456789
```

Represents:

```text
2025-07-10 14:30:15.123456789
```

Similarly,

```idris
MkOracleIntervalYM
    3
    6
```

Represents an interval of three years and six months.

These values participate naturally in both encoding and decoding.

```mermaid
flowchart LR

A[Oracle TIMESTAMP]

-->

B[OracleTimestamp]

-->

C[FromOracle]

-->

D[Application record]

```

The same mechanism works for every supported temporal type.

Applications therefore interact with strongly typed Idris values instead of parsing date and interval strings manually.

## Error Handling

Unlike many database libraries, this library does not throw exceptions for ordinary database failures.

Instead, every database operation explicitly returns either a successful result or an `OracleError`.

```idris
Either OracleError a
```

This makes failure part of the function's type and encourages applications to handle database errors explicitly.

A typical query therefore looks like:

```idris
result <-
    query_
        conn
        sql
        params
case result of
    Left err =>
        putStrLn (show err)
    Right rows =>
        ...
```

## The `OracleError` type

Every Oracle failure is represented by an `OracleError`:

```idris
record OracleError where
  constructor MkOracleError
  code        : Int32
  message     : String
  fnname      : String
  recoverable : Bool
```

An error contains information such as:

- Oracle error number
- Descriptive error message
- The function where the fail originated from
- Whether the error originated from Oracle or the library

For example,

```text
ORA-00942: table or view does not exist
```

Becomes an ordinary Idris value that can be inspected, logged, transformed, or propagated.

## Error propagation

Most library functions return

```idris
IO (Either OracleError a)
```

This allows callers to propagate failures naturally.

For example,

```idris
execute_ conn sql params
>>== \_ =>
commit conn
```

If the first operation fails, the second operation is never executed.

This keeps transaction logic concise while avoiding deeply nested pattern matches.

## Advanced Usage

Most users will only need the high-level API presented throughout this tutorial.

However, this library also exposes the underlying layers for applications requiring finer control over Oracle.

These include:

- Manual connection management
- Prepared statement reuse
- Raw query APIs
- Low-level ODPI-C bindings
- Custom row decoding
- Custom parameter encoding

## Manual connection management

Although this tutorial strongly recommends using

```idris
withConnection
```

There are situations where manually managing connections is appropriate.

Examples include:

- long-running servers
- custom connection pools
- embedded frameworks
- interoperability with existing resource managers

The lower-level API consists of

```idris
connect
disconnect
```

Applications using these functions become responsible for ensuring every successful connection is eventually released.

## Working directly with `OracleValue`

Most applications should use typed queries.

Occasionally, however, the schema may not be known until runtime.

In these situations, you can use `queryRaw`:

```idris
queryRaw
    : Connection
    -> String
    -> List BindParameter
    -> IO (Either OracleError (List (List OracleValue)))
```

This allows applications to inspect Oracle values dynamically.

This is useful for:

- Generic SQL clients
- Schema browsers
- Migration tools
- Interactive REPLs

## Custom decoding

Every typed query is built from two interfaces:

```idris
FromOracle
FromRow
```

Applications can define new instances to decode Oracle values directly into domain-specific types.

Similarly, `ToRow` allows records to be converted into collections of bind parameters.

This separation keeps database-specific logic isolated from application code.

## Querying

The query API provides a structured way to retrieve and decode data from Oracle.

Queries are represented by the `Query` record, while individual selected expressions are represented by `QueryColumn`. This allows the library to distinguish between ordinary Oracle expressions and expressions that require special handling, such as native Oracle JSON values.

The query API provides two levels of access to query results:

* **Raw queries** return Oracle values directly.
* **Typed queries** decode query results into user-defined Idris types.

The primary query functions are:

```idris
query
    : Connection
   -> Query
   -> IO (Either OracleError (List (List OracleValue)))

queryOne
    : Connection
   -> Query
   -> IO (Either OracleError (List OracleValue))

queryAs
    : FromOracle a
    => Connection
    -> Query
    -> IO (Either OracleError (List a))

queryOneAs
    : FromOracle a
    => Connection
    -> Query
    -> IO (Either OracleError a)
```

The exact result type of each function depends on whether the caller wants raw Oracle values or typed Idris values, and whether the query is expected to return multiple rows or a single row.

### Query

A `Query` describes a complete SQL query:

```idris
public export
record Query where
  constructor MkQuery
  columns  : List QueryColumn
  querybody : String
  binds    : List BindParameter
```

The `columns` field describes the expressions selected by the query.

The `querybody` field contains the remainder of the SQL query, beginning with the `FROM` clause and including any additional clauses required to identify or order the result rows.

The `binds` field contains the bind parameters used by the query.

For example:

```idris
MkQuery
  [ QueryColumn "id"
  , QueryColumn "name"
  ]
  "people WHERE active = :active ORDER BY id"
  [MkBindParameter ":active" (OracleBool True)]
```

Represents a query equivalent to:

```sql
SELECT
    id,
    name
FROM people
WHERE active = :active
ORDER BY id
```

The `Query` abstraction separates the three primary parts of a query:

1. **What is selected** — represented by `columns`.
2. **How rows are located and ordered** — represented by `querybody`.
3. **How values are bound** — represented by `binds`.

This also allows the query execution layer to transform special column types before Oracle executes the query.

### QueryColumn

A `QueryColumn` describes one expression in the `SELECT` list.

An ordinary column is represented as:

```idris
QueryColumn "name"
```

A JSON expression is represented as:

```idris
QueryColumnJSON "profile"
```

The two forms are handled differently by the query execution layer.

An ordinary column is selected directly:

```sql
SELECT name
FROM people
```

A JSON column is internally transformed into a textual CLOB representation:

```sql
SELECT JSON_SERIALIZE(profile RETURNING CLOB)
FROM people
```

The caller does not need to write `JSON_SERIALIZE` manually.

For example:

```idris
MkQuery
  [ QueryColumn "id"
  , QueryColumn "name"
  , QueryColumnJSON "profile"
  ]
  "people"
  []
```

is logically equivalent to:

```sql
SELECT
    id,
    name,
    JSON_SERIALIZE(profile RETURNING CLOB)
FROM people
```

A query may therefore contain any mixture of ordinary and JSON expressions:

```idris
MkQuery
  [ QueryColumn "id"
  , QueryColumnJSON "profile"
  , QueryColumn "name"
  ]
  "people WHERE id = :id"
  [MkBindParameter ":id" (OracleNumber 1)]
```

The selected expressions are:

1. `id` — an ordinary Oracle value.
2. `profile` — a JSON value serialized to a CLOB.
3. `name` — an ordinary Oracle value.

JSON handling therefore occurs at the **query-expression level** rather than in the low-level Oracle value retrieval path.

### Raw Queries

Raw queries expose Oracle values directly.

The lower-level query functions are useful when the result shape is dynamic, when the caller needs to inspect Oracle values directly, or when custom decoding is required.

For example:

```idris
query
  conn
  (MkQuery
    [ QueryColumn "name"
    , QueryColumn "age"
    ]
    "people ORDER BY id"
    [])
```

A result might look conceptually like:

```idris
Right
  [ [ OracleString "Alice"
    , OracleNumber 30
    ]
  , [ OracleString "Bob"
    , OracleNumber 42
    ]
  ]
```

A query therefore returns a list of rows, where each row contains the selected values as `OracleValue`s.

The `OracleValue` representation intentionally remains simple. Each Oracle datatype has a corresponding `OracleValue` constructor, allowing callers to inspect database values without committing to a particular application-level Idris type.

For example, an application may receive:

```idris
OracleString "Alice"
OracleNumber 30
OracleClob "Alice Notes"
OracleTimestamp ...
OracleBlob ...
```

Raw queries are particularly useful for:

* Dynamic query results
* Database inspection tools
* Generic database utilities
* Custom decoding logic
* Applications that do not have a fixed result type

Most application code, however, should generally prefer typed queries.

### Typed Queries

Typed queries decode query results directly into user-defined Idris types.

The typed query API consists of:

```idris
queryAs
    : FromOracle a
    => Connection
    -> Query
    -> IO (Either OracleError (List a))
```

and:

```idris
queryOneAs
    : FromOracle a
    => Connection
    -> Query
    -> IO (Either OracleError a)
```

A type used with these functions must have an appropriate `FromOracle` implementation.

For example:

```idris
public export
record Person where
  constructor MkPerson
  id      : Int
  name    : String
  profile : Profile
```

Assuming an appropriate `FromOracle Person` implementation exists, the query can be written as:

```idris
queryAs
  conn
  (MkQuery
    [ QueryColumn "id"
    , QueryColumn "name"
    , QueryColumnJSON "profile"
    ]
    "people ORDER BY id"
    [])
```

The result is:

```idris
Either OracleError (List Person)
```

A successful query that returns no rows produces:

```idris
Right []
```

A query or decoding failure produces:

```idris
Left error
```

`queryAs` is therefore the preferred API when the query result represents a known collection of application-level values.

### Querying a Single Row

When a query is expected to return one row, the library provides `queryOneAs`:

```idris
queryOneAs
    : FromOracle a
    => Connection
    -> Query
    -> IO (Either OracleError a)
```

For example:

```idris
queryOneAs
  conn
  (MkQuery
    [ QueryColumn "id"
    , QueryColumn "name"
    , QueryColumnJSON "profile"
    ]
    "people WHERE name = :name"
    [MkBindParameter ":name" (OracleString "Alice")])
```

The result is a single decoded `Person`.

Unlike `queryAs`, which represents zero rows as `Right []`, `queryOneAs` returns an error when the query does not produce the required row.

Queries passed to `queryOneAs` should therefore normally identify a single row, such as by querying a primary key or another unique predicate.

### The Decoding Pipeline

The conversion from Oracle query results into Idris application types happens in two conceptual stages:

```mermaid
flowchart LR

A[Oracle query]

-->

B[Query / QueryColumn]

-->

C[Oracle SQL]

-->

D[OracleValue rows]

-->

E[FromOracle]

-->

F[Idris type]

```

The query layer first determines how each selected expression should be represented in SQL.

For ordinary expressions:

```idris
QueryColumn "name"
```

the expression is selected directly.

For JSON expressions:

```idris
QueryColumnJSON "profile"
```

the query layer generates:

```sql
JSON_SERIALIZE(profile RETURNING CLOB)
```

The resulting Oracle values are then decoded through the normal Oracle value retrieval path.

Finally, the `FromOracle` implementation converts the resulting values into the requested Idris type.

This means JSON does not require a separate low-level JSON retrieval mechanism. It uses the existing CLOB retrieval mechanism and the same typed decoding infrastructure as other Oracle values.

### JSON Query Columns

JSON support is integrated directly into the general query API through `QueryColumnJSON`.

JSON is therefore not a separate query mechanism. A single query can contain ordinary Oracle expressions and JSON expressions simultaneously.

For example:

```idris
MkQuery
  [ QueryColumn "id"
  , QueryColumn "name"
  , QueryColumnJSON "profile"
  ]
  "people WHERE name = :name"
  [MkBindParameter ":name" (OracleString "Alice")]
```

The query execution layer generates SQL equivalent to:

```sql
SELECT
    id,
    name,
    JSON_SERIALIZE(profile RETURNING CLOB)
FROM people
WHERE name = :name
```

The JSON value is:

1. Selected as a native Oracle JSON value.
2. Serialized by Oracle using `JSON_SERIALIZE`.
3. Returned as a CLOB.
4. Retrieved using the existing CLOB handling.
5. Converted into the appropriate Idris representation by `FromOracle`.

The caller therefore only needs to indicate which selected expressions contain JSON:

```idris
QueryColumnJSON "profile"
```

The SQL transformation is handled internally.

This design has several advantages:

* JSON-specific SQL generation remains inside the query layer.
* The C shim does not require JSON-specific retrieval logic.
* JSON values use the existing CLOB retrieval mechanism.
* A single query can mix JSON and non-JSON columns.
* Typed queries can decode JSON into nested Idris data types.
* `queryAs` and `queryOneAs` use the same API regardless of whether the result contains JSON columns.

### Example: Typed JSON Result

Suppose the `profile` column contains:

```json
{
  "department": "Engineering",
  "skills": [
    "Idris2",
    "Haskell",
    "C"
  ],
  "active": true
}
```

An Idris representation might be:

```idris
public export
record Profile where
  constructor MkProfile
  department : String
  skills     : List String
  active     : Bool
```

The enclosing row can then be represented as:

```idris
public export
record PersonProfile where
  constructor MkPersonProfile
  id      : Int
  name    : String
  profile : Profile
```

The query can select both ordinary and JSON columns:

```idris
queryOneAs
  conn
  (MkQuery
    [ QueryColumn "id"
    , QueryColumn "name"
    , QueryColumnJSON "profile"
    ]
    "people WHERE name = :name"
    [MkBindParameter ":name" (OracleString "Alice")])
```

The result is decoded into:

```idris
PersonProfile
```

with the nested JSON document decoded into:

```idris
Profile
```

From the application's perspective, the JSON document is simply another typed component of the query result.

### Raw Queries vs Typed Queries

The two query APIs serve different purposes.

#### Raw query API

Use raw queries when:

* The result shape is dynamic.
* The caller needs to inspect Oracle values directly.
* The result does not map naturally to a predefined Idris record.
* The caller wants to perform custom decoding.

For example:

```idris
query
  conn
  (MkQuery
    [ QueryColumn "id"
    , QueryColumnJSON "profile"
    ]
    "people"
    [])
```

This returns raw Oracle values.

#### Typed query API

Use typed queries when:

* The result shape is known.
* The caller has an Idris type representing the result.
* JSON should be decoded into nested Idris types.
* The application wants a strongly typed representation of query results.

For example:

```idris
queryOneAs
  conn
  (MkQuery
    [ QueryColumn "id"
    , QueryColumn "name"
    , QueryColumnJSON "profile"
    ]
    "people WHERE name = :name"
    [MkBindParameter ":name" (OracleString "Alice")])
```

The typed API is generally preferred for application-level code, while the raw API is useful for lower-level and dynamic database access.

### Query Design

The `Query` and `QueryColumn` abstractions intentionally separate three concerns:

1. **What is selected**

   Represented by `QueryColumn`.

2. **How rows are located and ordered**

   Represented by `querybody`.

3. **How bind parameters are supplied**

   Represented by `binds`.

This separation allows the query layer to transform special column types, such as JSON, without requiring callers to manually construct database-specific SQL.

It also provides a natural extension point for future column representations that require SQL-level transformations before being decoded by Idris.

For example, JSON columns are transformed using:

```sql
JSON_SERIALIZE(expression RETURNING CLOB)
```

while the remainder of the query remains unchanged.

The resulting architecture is:

```text
                         Query
                           |
                  +--------+--------+
                  |                 |
             QueryColumn      QueryColumnJSON
                  |                 |
                  |          JSON_SERIALIZE(...)
                  |                 |
                  +--------+--------+
                           |
                       Oracle SQL
                           |
                      Query Result
                           |
                   OracleValue rows
                           |
                      FromOracle
                           |
                      Idris Type
```

The important property is that JSON handling is performed at the query-expression level rather than by modifying the low-level Oracle value retrieval path.

This keeps the existing C shim and general Oracle decoding machinery independent of JSON-specific behavior, while allowing JSON values to participate naturally in ordinary typed queries.

## Testing

This library includes a comprehensive integration test suite covering the major features of the library.

The tests execute against a real Oracle database and verify both the high-level Idris2 API and the underlying ODPI-C bindings.

Current coverage includes:

- Connection management
- Prepared statements
- Parameter binding
- Query execution
- Typed row decoding
- Transactions
- LOB handling
- Oracle error handling

### Test database

The test suite utilizes an actual Oracle database (via docker).

During testing the suite creates a small schema containing representative Oracle types, including:

- numeric values
- strings
- booleans
- timestamps
- intervals
- CLOBs
- BLOBs
- JSON

Before each test the database is reset to a known state.

This allows every test to run independently without relying on execution order.

### Running the test suite

Running `make test` setups up the oracle database via docker, builds the test suite, and runs it.
