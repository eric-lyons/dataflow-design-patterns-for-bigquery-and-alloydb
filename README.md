# Dataflow Prime Design Patterns for BigQuery and AlloyDB

<ul>
<li>BigQuery to AlloyDB (Python)<br>
<li>AlloyDB to BigQuery (Python)<br>
<li>BigQuery to AlloyDB (Java)<br>
<li>AlloyDB to BigQuery (Java)<br>
</ul>

The Python based pipelines are targeted at non-technical data engineers or an individual that would be categorized as an analyst or even analytics engineers. The purpose is to allow this cohort to quickly create a pipeline and customize it in a familiar scripting language. This would be considered more self-serve. Some common use-case would be an analytics engineer who wants to explore the functionality of AlloyDB with real data that exists in their BigQuery Instance or a analytics who wants to create a simple pipeline from a higher throughput database like Alloy to allow more analytical or ML procedures in BigQuery. They should be able to customize the pipeline on their own and be able to customize the DLP integration if any data needs to be scrubbed in transit. 


The Java based pipelines generally will hold higher performance and the end goal would be to allow them to be templatized in the GCP console. A customer engineer is working with an existing BigQuery customer. They may use a transactional DB or be interested in real time analytic use-cases. The customer engineer would be able to use the template to spin up an AlloyDB database within a shared VPC as the Bigquery instance, then move a set of tables from BQ to AlloyDB in order for the customer to explore AlloyDB’s features with their own data. The data should go through DLP for security reasons to flag any PII and the customer should be able to enter in a set up tables and a row limit. 






