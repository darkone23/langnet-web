import polars as pl
from typing import Dict, Any


def create_sample_dataframe():
    data = {
        "name": ["Alice", "Bob", "Charlie", "Diana"],
        "age": [30, 25, 35, 28],
        "city": ["New York", "San Francisco", "Chicago", "Seattle"],
        "salary": [90000, 75000, 95000, 85000]
    }
    return pl.DataFrame(data)


def example_dataframe_operations():
    df = create_sample_dataframe()
    
    print("Original DataFrame:")
    print(df)
    
    print("\nFiltered (age > 28):")
    print(df.filter(pl.col("age") > 28))
    
    print("\nSorted by salary (descending):")
    print(df.sort("salary", descending=True))
    
    print("\nAggregated stats:")
    print(df.select([
        pl.col("age").mean().alias("avg_age"),
        pl.col("salary").sum().alias("total_salary"),
        pl.col("salary").mean().alias("avg_salary")
    ]))
    
    print("\nGroup by city:")
    print(df.group_by("city").agg([
        pl.col("salary").mean().alias("avg_salary"),
        pl.len().alias("count")
    ]))
    
    return df


def example_data_transformation():
    df = create_sample_dataframe()
    
    transformed = df.with_columns([
        (pl.col("salary") * 12).alias("annual_salary"),
        pl.col("city").str.to_uppercase().alias("city_upper"),
        pl.col("age").rank().alias("age_rank")
    ])
    
    print("\nTransformed DataFrame:")
    print(transformed)
    
    return transformed
