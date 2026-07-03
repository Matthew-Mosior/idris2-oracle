module Oracle.FFI.DateTime

%default total

||| Return the address of the dpiTimestamp embedded inside a dpiData value.
|||
||| The returned pointer is owned by the current Oracle row and remains valid
||| until the next fetch or until the statement is released.
|||
||| Returns NULL when the supplied dpiData pointer is NULL.
|||
export %foreign "C:oracle_data_timestamp,oracle-idris"
prim__dataTimestamp : AnyPtr -> PrimIO AnyPtr

||| Retrieve the year component of a timestamp.
|||
export %foreign "C:oracle_timestamp_year,oracle-idris"
prim__timestampYear : AnyPtr -> PrimIO Int32

||| Retrieve the month component of a timestamp.
|||
export %foreign "C:oracle_timestamp_month,oracle-idris"
prim__timestampMonth : AnyPtr -> PrimIO Int32

||| Retrieve the day component of a timestamp.
|||
export %foreign "C:oracle_timestamp_day,oracle-idris"
prim__timestampDay : AnyPtr -> PrimIO Int32

||| Retrieve the hour component of a timestamp.
|||
export %foreign "C:oracle_timestamp_hour,oracle-idris"
prim__timestampHour : AnyPtr -> PrimIO Int32

||| Retrieve the minute component of a timestamp.
|||
export %foreign "C:oracle_timestamp_minute,oracle-idris"
prim__timestampMinute : AnyPtr -> PrimIO Int32

||| Retrieve the second component of a timestamp.
|||
export %foreign "C:oracle_timestamp_second,oracle-idris"
prim__timestampSecond : AnyPtr -> PrimIO Int32

||| Retrieve the fractional second component of a timestamp.
|||
||| The returned value is expressed in nanoseconds.
|||
export %foreign "C:oracle_timestamp_fsecond,oracle-idris"
prim__timestampNanosecond : AnyPtr -> PrimIO Int32

||| Retrieve the timezone hour offset.
|||
||| This is only meaningful for TIMESTAMP WITH TIME ZONE values.
|||
export %foreign "C:oracle_timestamp_tz_hour,oracle-idris"
prim__timestampTZHour : AnyPtr -> PrimIO Int32

||| Retrieve the timezone minute offset.
|||
||| This is only meaningful for TIMESTAMP WITH TIME ZONE values.
|||
export %foreign "C:oracle_timestamp_tz_minute,oracle-idris"
prim__timestampTZMinute : AnyPtr -> PrimIO Int32

||| Return the dpiIntervalDS embedded inside a dpiData value.
|||
||| The returned pointer is owned by Oracle and must not be freed.
|||
export %foreign "C:oracle_data_interval_ds,oracle-idris"
prim__dataIntervalDS : AnyPtr -> PrimIO AnyPtr

||| Retrieve the day component of an INTERVAL DAY TO SECOND value.
|||
export %foreign "C:oracle_interval_ds_days,oracle-idris"
prim__intervalDSDays : AnyPtr -> PrimIO Int32

||| Retrieve the hour component of an INTERVAL DAY TO SECOND value.
|||
export %foreign "C:oracle_interval_ds_hours,oracle-idris"
prim__intervalDSHours : AnyPtr -> PrimIO Int32

||| Retrieve the minute component of an INTERVAL DAY TO SECOND value.
|||
export %foreign "C:oracle_interval_ds_minutes,oracle-idris"
prim__intervalDSMinutes : AnyPtr -> PrimIO Int32

||| Retrieve the second component of an INTERVAL DAY TO SECOND value.
|||
export %foreign "C:oracle_interval_ds_seconds,oracle-idris"
prim__intervalDSSeconds : AnyPtr -> PrimIO Int32

||| Retrieve the fractional second component of an INTERVAL DAY TO SECOND value.
|||
||| The returned value is expressed in nanoseconds.
|||
export %foreign "C:oracle_interval_ds_fseconds,oracle-idris"
prim__intervalDSNanoseconds : AnyPtr -> PrimIO Int32

||| Return the dpiIntervalYM embedded inside a dpiData value.
|||
||| The returned pointer is owned by Oracle and must not be freed.
|||
export %foreign "C:oracle_data_interval_ym,oracle-idris"
prim__dataIntervalYM : AnyPtr -> PrimIO AnyPtr

||| Retrieve the year component of an INTERVAL YEAR TO MONTH value.
|||
export %foreign "C:oracle_interval_ym_years,oracle-idris"
prim__intervalYMYears : AnyPtr -> PrimIO Int32

||| Retrieve the month component of an INTERVAL YEAR TO MONTH value.
|||
export %foreign "C:oracle_interval_ym_months,oracle-idris"
prim__intervalYMMonths : AnyPtr -> PrimIO Int32
