<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>




<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

<!-- PROJECT LOGO -->


<h3 align="center">BigQuery To AlloyDB</h3>

  <p align="center">
    project_description
    <br />
    <a href="https://github.com/eric-lyons/dataflow-design-patterns-for-bigquery-and-alloydb"><strong>Explore the docs »</strong></a>
    <br />
    <a href="https://github.com/eric-lyons/dataflow-design-patterns-for-bigquery-and-alloydb/issues">Report Bug</a>
    ·
    <a href="https://github.com/eric-lyons/dataflow-design-patterns-for-bigquery-and-alloydb/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This is a framework to allow users to quick start AlloyDB usage by migrating data from BigQuery to AlloyDB with a simple and fully cusomtizable Dataflow pipeline.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* <a href="https://www.python.org/"> Python </a> <br>
* <a href="https://cloud.google.com/dataflow"> Dataflow</a> <br>
* <a href="https://cloud.google.com/bigquery"> BigQuery</a> <br>
* <a href="https://cloud.google.com/alloydb/docs/overview"> AlloyDB</a> <br>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->

### Prerequisites
An AlloyDB cluster and BigQuery Dataset/Table. If you do not already have these please see the terraform directory of the repo which will allow you to create these resources via IAC (infrastructure as code).

Among the parameters required to run the pipeline, there are three we would suggest setting as enviroment variables or using <a href="https://cloud.google.com/secret-manager"> Cloud Secret Manager </a> : DESTIONATION_IP, ALLOYUSERNAME, DESTINATION_IP.

We would also suggest creating the schema in the AlloyDB table first to improve ease of use, if you want to use this table for other workflows. To do this, please use the PSQL CLI tool and use this command:

For more information and details on this process, please visit this <a href="https://www.postgresql.org/docs/current/tutorial-table.html#:~:text=You%20can%20create%20a%20new,psql%20with%20the%20line%20breaks.">link </a>.

```
CEATE TABLE TABLENAME (
    order_id varchar(80),
    order_date varchar(80),
    ship_date varchar(80),
    )
```

### Installation

1. Open the GCloud terminal
2. Clone the repo

   ```
   git clone https://github.com/eric-lyons/dataflow-design-patterns-for-bigquery-and-alloydb.git
   ```

3. Navigate to the Python Directory

   ```
   cd dataflow-design-patterns-for-bigquery-and-alloydb/python/
   ```

4. Enter your configuration in the Makefile. Use vim or your favorite editor. 

   ```
   vim Makefile

   Then update the following values. Replace [CHANGE] with the values. Be sure to remove the brackets.
   GCP_PROJECT ?= [CHANGE]
   GCP_REGION ?= [CHANGE]
   DATASET ?= [CHANGE]
   TABLE ?= [CHANGE]
   LIMIT ?= [CHANGE]
   BQPROJECTID ?= [CHANGE]
   ALLOYUSERNAME ?= [CHANGE]
   DATABASE_NAME ?= [CHANGE]
   PORT ?= [CHANGE]
   DESTINATION_TABLE ?= [CHANGE]
   DESTINATION_PASSWORD ?= [CHANGE]
   DESTINATION_IP ?= [CHANGE]
   ```

5. Navigate to the bqtoalloy directory. Open the main.py file, please review the code and then specify the columns you would like written to AlloyDB, by editting this function, and replace the column names in both the key pairs. If you had a two column table with the first column called orders and the second column called id, you would replace col1 and col2 in the example below with orders and id. 

    ```
    cd bqtoalloy

    def map_to_beam_nuggets_data(element):
        return {
            'col1': element['col1'],
            'col2': element['col2'],
        }
    ```



6. Initialize the template.

    ```
    make init
    ```

7. Create the Dataflow Template.

    ```
    make template
    ```

8. Run the template and create the Dataflow job.

    ```
    make run
    ```

9. In the GCloud search bar, enter "Dataflow". Select Dataflow jobs to check the progress.

10. Once the job has completed, check the results in AlloyDB.

11. If you hardcoded any parameters, remove any passwords or PII from the Makefile if it is not in use.

12. Once the job status is complete, ssh to the AlloyDB instance. Replace ALLOYIP and DBUSERNAME. You will be prompted to enter in the user's password.  Use \c to connect to the database. Then you can query the results to check the pipeline.

```
psql -h ALLOYIP -U DBUSERNAME

\c DATABASENAME

SELECT * FROM TABLENAME;
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

The Python based pipelines are targeted at moderately-technical data engineers or an individual that would be categorized as an analyst or even analytics engineers. The purpose is to allow this cohort to quickly create a pipeline and customize it in a familiar scripting language. This would be considered more self-serve.
<br>
Some common use-case would be an analytics engineer who wants to explore the functionality of AlloyDB with real data that exists in his/her/their BigQuery Instance.

This framework uses a Makefile to instatinate a Dataflow Flex template. This will create a Docker image in container registry and then you can re-use the template with the simple command of make run.

AlloyDB can use the default network provided in a GCP project. This is generally too broad for most realworld use-cases. We would suggest setting up your own network to specific to your use-case. If you wish to specify a subnetwork, please add --subnetwork to the makefile where the dataflow parameters are set. For more information on how to properly pass this arg, [please visit this page](https://cloud.google.com/dataflow/docs/guides/specifying-networks). 

### The Code

The pipeline is ran via the run function. This utlizies the classes to instatiate the connections with Bigquery via Bigquery.io and Alloy via Beam Nuggets. These classes are controlled by the parameters specifed in the Makefile which are used in the MyOptions class. This uses Python's argparge library.

There is the map_to_beam_nuggets_data function which is used to tranform the output of BigQuery into the structure that Beam Nuggets requires. This can also be parameterized, but in order to make sure users review the code, they will need to manually update this right now.

To update this pipeline to write to another database besides AlloyDb, please review the sink_config definition and redefine the drivername to the corresponding DB.


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap


- [ ] Support migration of nested records
- [ ] Add bad record queue for failed writes to AlloyDB.
- [ ] Add the ability to encrypt certain columns with Cloud KMS
- [ ] Add customizable unit tests

See the [open issues](https://github.com/eric-lyons/dataflow-design-patterns-for-bigquery-and-alloydb/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add some New Feature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
