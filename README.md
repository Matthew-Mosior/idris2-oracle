# Idris2 bindings to the Oracle ODPI-C API

This library provides a modern Oracle Database client library for Idris2 built on top of Oracle's [ODPI-C API](https://github.com/oracle/odpi). It combines a low-level FFI with a high-level, type-safe API supporting prepared statements, transactions, typed row decoding, LOBs, and Oracle-native data types, allowing Idris2 applications to interact with Oracle databases safely and efficiently.

## Introduction

`idris2-oracle` is a high-level Idris2 interface to Oracle Database built on top of Oracle's official **ODPI-C** library.

The library provides low-level FFI bindings to the complete ODPI-C API together with a type-safe, idiomatic Idris2 interface for preparing statements, binding parameters, executing queries, managing transactions, working with LOBs, and decoding results into ordinary Idris records.

Unlike traditional database bindings that expose raw pointers and manual resource management, `idris2-oracle` uses Idris2's type system together with linear resource management to ensure that database resources are acquired and released safely while presenting a pleasant functional API.

## Features

Current capabilities include:
-   **Complete Oracle connectivity**
    -   Connect and disconnect from Oracle databases
    -   Transaction management
    -   Automatic cleanup of database resources
-   **Prepared statements**
    -   Prepare SQL once and execute multiple times
    -   Named parameter binding
    -   Automatic statement lifetime management
    -   Statement reuse
-   **Rich type support**
    -   `VARCHAR2`
    -   `NUMBER`
    -   `BOOLEAN`
    -   `CLOB`
    -   `BLOB`
    -   `TIMESTAMP`
    -   `TIMESTAMP WITH TIME ZONE`
    -   `INTERVAL YEAR TO MONTH`
    -   `INTERVAL DAY TO SECOND`
-   **Typed decoding**
    -   Automatic conversion from Oracle values to Idris types via `FromOracle`
    -   Automatic row decoding via `FromRow`
    -   Typed query APIs returning user-defined records
-   **Type-safe parameter encoding**
    -   Automatic conversion to Oracle bind values via `ToOracle`
    -   Record encoding through `ToRow`
-   **LOB support**
    -   Read and write `CLOB`
    -   Read and write `BLOB`
    -   Automatic LOB resource management
-   **Transaction support**
    -   Commit
    -   Rollback
    -   Explicit transaction boundaries
    -   ACID-compliant operations
-   **Error handling**
    -   Oracle errors are represented as ordinary Idris values
    -   Rich diagnostic information
    -   No exceptions required
-   **Resource safety**
    -   Automatic release of
        -   statements
        -   query metadata
        -   temporary buffers
        -   LOB handles
    -   Bracket-style APIs throughout (via `idris2-elin`)
-   **High-level query interface**
    -   Raw queries returning `OracleValue`
    -   Typed queries returning Idris records
    -   Single-row queries
    -   Exactly-one-row queries
-   **Comprehensive integration test suite**
    -   Connection tests
    -   Statement tests
    -   Parameter binding tests
    -   Query tests
    -   Typed decoding tests
    -   Transaction tests

## Why `idris2-oracle`?

Most Oracle client libraries fall into one of two categories:
- Thin C bindings that expose Oracle's underlying APIs almost directly. While these provide maximum flexibility, they also require callers to manually manage statements, buffers, LOB locators, and other native resources. Small mistakes can easily lead to memory leaks or invalid resource usage.
- Heavyweight object-relational frameworks that hide much of Oracle's functionality behind large abstraction layers. These often sacrifice transparency, make advanced Oracle features difficult to access, and provide little static verification of application logic.

This library aims for a middle ground between the aforementioned categories.  It exposes Oracle's capabilities through a small, composable API while using Idris2's type system to eliminate many classes of runtime errors. Resources are managed automatically, database values are represented explicitly, and query results can be decoded directly into ordinary Idris records without reflection or runtime code generation.

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

This library is built as a small Idris2 layer on top of Oracle’s ODPI-C library. ODPI-C provides the low-level bridge to Oracle Client libraries and the database itself, while `idris2-oracle` adds a type-safe Idris2 API for connections, statements, transactions, parameter binding, row decoding, and LOB handling.

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

## Installation

This library depends on Oracle’s ODPI-C layer, and ODPI-C in turn requires Oracle Client libraries at runtime. Oracle’s documentation states that these libraries can come from Oracle Instant Client, an Oracle Database installation, or a full Oracle Client installation. ODPI-C also loads the client library dynamically at runtime, so the application must be able to locate the Oracle Client shared libraries when it starts.

Running `make install` builds and installs the library.

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

`execute_` is intended for SQL that does not return rows, including

-   `CREATE TABLE`    
-   `CREATE INDEX`    
-   `INSERT`    
-   `UPDATE`    
-   `DELETE`    
-   `ALTER`    
-   `DROP`    

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

Every execution returns

```idris
Either OracleError ()
```

making success and failure explicit.

Most database operations therefore follow the same pattern:

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

`idris2-oracle` exposes prepared statements through the `Statement` type.

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

-   `withConnection`    
-   `withStatement`    
-   `withQueryInfo`
    

Each acquires a resource, executes user code, and guarantees cleanup.

## Bind Parameters

Rather than constructing SQL strings manually, applications should bind values through named parameters.

Binding provides several advantages:

-   avoids SQL injection
-   improves statement reuse
-   avoids manual quoting
-   allows Oracle to optimize execution
    

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

-   `OracleNull`    
-   `OracleString`    
-   `OracleNumber`    
-   `OracleBool`    
-   `OracleClob`    
-   `OracleBlob`    
-   `OracleTimestamp`    
-   `OracleTimestampTZ`    
-   `OracleIntervalYM`    
-   `OracleIntervalDS`
    

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

## Querying

Retrieving data from Oracle begins with one of the query functions provided by the library.

At the lowest level, queries return rows of `OracleValue`s exactly as they are represented by Oracle.

```idris
queryRaw
    : Connection
   -> String
   -> List BindParameter
   -> IO (Either OracleError (List (List OracleValue)))
```

A query therefore returns a list of rows, where each row is a list of `OracleValue`s.

For example,

```sql
SELECT
    name,
    age
FROM people
ORDER BY id
```

Might produce:

```idris
Right
[
    [ OracleString "Alice"
    , OracleNumber 30
    ]
,   [ OracleString "Bob"
    , OracleNumber 42
    ]
]
```

This representation is intentionally simple. Every Oracle datatype has a corresponding `OracleValue` constructor, allowing callers to inspect values without committing to a particular Idris type.

Most applications, however, should rarely need to work directly with `OracleValue`.

### Query lifecycle

Every query follows the same execution pipeline.

```mermaid
flowchart LR

A[SQL]

-->

B[Prepare]

-->

C[Bind]

-->

D[Execute]

-->

E[Fetch]

-->

F[Decode]

-->

G[Result]

```

Internally this corresponds to:
1.  Preparing the SQL statement
2.  Binding parameters
3.  Executing the statement
4.  Fetching every row
5.  Decoding Oracle values
6.  Returning the result

Because `queryRaw` uses `withStatement`, the prepared statement is released automatically before the function returns.

## Typed Queries

While `queryRaw` exposes Oracle values directly, most Idris programs are interested in ordinary Idris records.

For that reason the library provides

```idris
query_
    : FromRow a
    => Connection
    -> String
    -> List BindParameter
    -> IO (Either OracleError (List a))
 ```

which automatically decodes every row using the `FromRow` interface.

Suppose we have:

```idris
record Person where
    constructor MkPerson
    name : String
    age  : Double

implementation FromRow Person where
    ...
```

Then querying becomes:

```idris
people <-
    query_
        conn
        """
        SELECT
            name,
            age
        FROM people
        """
        []
```

The result is then:

```idris
Either OracleError (List Person)
```

Instead of:

```idris
Either OracleError
    (List (List OracleValue))
```

This removes nearly all manual decoding from application code.

## The decoding pipeline

The conversion from Oracle rows into Idris records happens in two stages.

```mermaid
flowchart LR

A[OracleValue]

-->

B[FromOracle]

-->

C[Idris values]

-->

D[FromRow]

-->

E[Application record]

```

`FromOracle`

: Converts an individual Oracle value into a single Idris value.

`FromRow`

: Combines several decoded values into an application record.

This separation allows primitive conversions to be reused across every record type in the application.

## Querying a single row

Frequently a query is expected to return at most one row.

For these situations the library provides

```idris
queryOne
    : FromRow a
    => Connection
    -> String
    -> List BindParameter
    -> IO (Either OracleError (Maybe a))
```

Suppose we have:

```idris
employee <-
    queryOne
        conn
        """
        SELECT
            name,
            age
        FROM people
        WHERE id = :id
        """
        [
            MkBindParameter
                ":id"
                (OracleNumber 1)
        ]

```

The result is then:

```idris
Either OracleError (Maybe Person)
```

`queryOne` makes the absence of a matching row explicit.

## Requiring exactly one row

Sometimes returning zero rows is an error (primary-key lookups are a common example).

For these situations, the library provides:

```idris
queryExactlyOne
    : FromRow a
    => Connection
    -> String
    -> List BindParameter
    -> IO (Either OracleError a)
```

`queryExactlyOne` fails if:
-   No rows are returned
-   More than one row is returned

This eliminates an entire class of application-level checks.

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

The library exposes the three standard transaction operations:

-   `commit`    
-   `rollback`

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
-   atomicity
-   consistency
-   isolation
-   durability

Transactions also reduces unnecessary commits, and is almost always preferable to committing after every statement.

## Working with LOBs

Oracle supports two large-object types:
-   `CLOB`    
-   `BLOB`
    
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

```
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

Unlike many database libraries, `idris2-oracle` does not throw exceptions for ordinary database failures.

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
-   Oracle error number
-   Descriptive error message
-   The function where the fail originated from    
-   Whether the error originated from Oracle or the library

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
-   Manual connection management
-   Prepared statement reuse
-   Raw query APIs
-   Low-level ODPI-C bindings   
-   Custom row decoding   
-   Custom parameter encoding

## Manual connection management

Although this tutorial strongly recommends using

```idris
withConnection
```

There are situations where manually managing connections is appropriate.

Examples include:
-   long-running servers
-   custom connection pools
-   embedded frameworks
-   interoperability with existing resource managers

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
-   Generic SQL clients
-   Schema browsers
-   Migration tools
-   Interactive REPLs
    
## Custom decoding

Every typed query is built from two interfaces:

```idris
FromOracle
FromRow
```

Applications can define new instances to decode Oracle values directly into domain-specific types.

Similarly, `ToRow` allows records to be converted into collections of bind parameters.

This separation keeps database-specific logic isolated from application code.

## Low-level FFI

The library intentionally exposes the underlying ODPI-C bindings.

Advanced users can build additional abstractions on top of:
-   statements
-   query metadata
-   LOB APIs
-   connection pools
-   Oracle-specific features

## Testing

This library includes a comprehensive integration test suite covering the major features of the library.

The tests execute against a real Oracle database and verify both the high-level Idris2 API and the underlying ODPI-C bindings.

Current coverage includes:
-   Connection management
-   Prepared statements
-   Parameter binding
-   Query execution
-   Typed row decoding
-   Transactions
-   LOB handling
-   Oracle error handling
    
## Running the test suite

The project provides a single command for building and executing every integration test.

```bash
make test
```

## Test database

The integration tests utilize an actual Oracle database (via docker).

During testing the suite creates a small schema containing representative Oracle types, including:
-   numeric values
-   strings
-   booleans
-   timestamps
-   intervals
-   CLOBs
-   BLOBs

Before each test the database is reset to a known state.

This allows every test to run independently without relying on execution order.
