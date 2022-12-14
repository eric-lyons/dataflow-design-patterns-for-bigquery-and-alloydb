# https://cloud.google.com/dataflow/docs/quickstarts/create-pipeline-python
# https://cloud.google.com/dataflow/docs/guides/templates/creating-templates#python
# https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates
# https://yaqs.corp.google.com/eng/q/8693213918220255232
# https://henrysuryawirawan.com/posts/dataflow-secret-manager/
import os
import argparse
import apache_beam as beam
import logging
from apache_beam.io import ReadFromText
from apache_beam.io import Read
from apache_beam.io import WriteToText
from apache_beam.io import WriteToBigQuery
from apache_beam.io import BigQuerySource
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions
from apache_beam.io.gcp.internal.clients import bigquery
from apache_beam.dataframe.io import read_csv
from beam_nuggets.io import relational_db
import re


class MyOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            '--dataset',
            help='BQ dataset',
            required=True
        )
        parser.add_argument(
            '--table',
            help='BQ table',
            required=True
        )
        parser.add_argument(
            '--destinationip',
            help='alloy db cluster ip',
            required=False
        )
        parser.add_argument(
            '--destinationtable',
            help='alloy db table',
            required=False
        )
        parser.add_argument(
            '--destinationpassword',
            help='alloy db password',
            required=False
        )
        parser.add_argument(
            '--alloyusername',
            help='alloydb username',
            required=False
        )
        parser.add_argument(
            '--database_name',
            help='alloydb database_name',
            required=False
        )
        parser.add_argument(
            '--bqprojectid',
            help='project_id',
            required=False
        )
        parser.add_argument(
            '--port',
            help='alloydb_port',
            required=False
        )
        parser.add_argument(
            '--limit',
            help='query limit',
            type = int,
            required=False
        )

class db_reader():
    def __init__(self, project, dataset, table, limit):
        self.project = project
        self.dataset = dataset
        self.table = table
        self.limit = limit
        
    # this defines the query that will be run against the BigQuery table for the source of the data. 
    def sql_query(self):
        sql = f'SELECT * FROM `{self.project}.{self.dataset}.{self.table}` 'f'LIMIT {self.limit}'
        return sql

# this defines the connection to AlloyDB.
class db_writer():
    def __init__(self, hostname, port, username, password, database_name, table_name):
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.database_name = database_name
        self.table_name = table_name
    # this also could be refactored to use another JDBC driver if you wish to adapt this for a different SQL dialect.
    def sink_config(self):
        sink_config = relational_db.SourceConfiguration(
            drivername='postgresql+pg8000',
            host=self.hostname,
            port=self.port,
            username=self.username,
            password=self.password,
            database=self.database_name,
            create_if_missing=True,
        )

        return sink_config
    
    def table_config(self):
        table_config = relational_db.TableConfiguration(
            name=self.table_name,
            create_if_missing=True
        )
        return table_config

         
def map_to_beam_nuggets_data(element):
    return {
        'col1': element['col1'],
        'col2': element['col2'],
    }


# this is the controller function
def run(save_main_session=True):
    beam_options = PipelineOptions()
    args = beam_options.view_as(MyOptions)
    with beam.Pipeline(options=beam_options) as p:
        db_source = db_reader(args.bqprojectid, args.dataset, args.table, args.limit)
        db = db_writer(args.destinationip, args.port, args.alloyusername, args.destinationpassword, args.destinationtable, args.database_name)
              # Result from BigQuery.
        result = (p | beam.io.ReadFromBigQuery(use_standard_sql=True, query=db_source.sql_query()))

        # Sink result to GCS.
        result | 'Write to GCS' >> WriteToText(URI)

        # Map to result to Beam Nuggets data and Sink result to the database.
        (result
         | 'Map to beam nuggets data' >> beam.Map(map_to_beam_nuggets_data)
         | 'Write to Database' >> relational_db.Write(
                    source_config=(db.sink_config()),
                    table_config=(db.table_config())
                ))


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run()
