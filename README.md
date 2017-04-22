# SynopseTestReplication

Using Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez, Synopse Informatique - http://synopse.info

Test taken from SynSelfTests.pas and modified

All test have 2 databases - Master and Slave. After modifying the Master the changes are replicated to the Slave. Before the Delete transaction the Master is newly created to make sure it is the first transaction and the current version number is calculated from the Master records.
1. Test - Add 10 records and delete the first one -> passed
2. Test - Add 10 records and delete the last one -> failed
3. Test - Add 1 record and delete it again -> failed

Relates to pull request https://github.com/synopse/mORMot/pull/37/commits/1f8e4ddc9dfe96a22cad06feb7d0663361b0b7ab

The problem happens in the rare event that a delete is the first transaction after starting the program and the deleted record has the highest version number.
