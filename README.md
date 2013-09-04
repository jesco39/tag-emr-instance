Usage
=====

    tag_emr_instance.sh -c s3://bucket/path/to/tags.txt

What
====

This is a short script that, once ran from inside a running EMR/EC2
instance, it will [tag][] this instance with the provided tags.

If used as a [bootstrap action][], which is actually the original purpose of
this script, resource (instance) tagging becomes a more robust and
passive process: every EMR instance created will apply its tags during
initialization -- or just fail and thus abort its initialization.

Contrasting with a reactive approach, where a process monitors the list
of created Elastic MapReduce jobflows, enumerates its instances and than
tags those instances, the "bootstrap action approach" is supposedly more
robust as every running instance **was** tagged before it became
operational.


Another nice thing about doing tagging as a [bootstrap action][] is that it
decouples tagging support from the underlying framework used with EMR:
be it a JAR application, a Streaming application, a MrJob script or
whatever, it will Just Work &copy;.

Contents
========

* `tag_emr_instance.sh`, our bootstrap script.
* `tags.txt`, a sample file with tags.

How
===

Add the following [bootstrap action][] to your EMR job description:

* **Name:** TagInstances
* **Path (to script):** `s3://bucket/path/to/tag_emr_instance.sh`
* **Arguments:** `-c=s3://bucket/path/to/tags.txt`

Enjoy. :)

For instance, to add such [bootstrap action][] to a MrJob script, just follow the example bellow:

    runners:
        emr:
            bootstrap_actions:
            - s3://elasticmapreduce/bootstrap-actions/configurations/latest/memory-intensive
            - s3://bucket/path/to/tag_emr_instance.sh -c=s3://bucket/path/to/tags.txt


Notice:

* Tags are provided as arguments to this [bootstrap action][].
* In this version we re use the credentials that are already configured for EMR, so you need to make sure that your IAM user for EMR has the create tags permission.

AWS credentials and security considerations
===========================================

Internally, this script executes some EC2 scripts that require access to
Amazon Web Services credentials (AWS_ACCESS_KEY, AWS_SECRET_KEY) being
available as environment variables at execution time.

In this version we simply re use the credentials that are passed to the EMR cluster. This is take from core-site.xml in the clusters hadoop config location. Usually /home/hadoop/conf/core-site.xml.

The minimal required action for this script to work is "ec2:CreateTags",
so the following would be a usable IAM policy for a user who's only purpose
it is to tag EMR instances:

    {
      "Statement": [
        {
          "Action": "ec2:CreateTags",
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }


License and code location
=========================

This code is licensed under a MIT License and hosted in
https://github.com/jesco39/tag-emr-instance.

[tag]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html (Tagging Your EC2 Resources)

[bootstrap action]: http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/Bootstrap.html (Bootstrap Actions)

[Instance Metadata Service]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html
