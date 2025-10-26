^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package gz_sim_vendor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

0.2.1 (2025-02-19)
------------------
* Bump version to 9.1.0 (`#9 <https://github.com/gazebo-release/gz_sim_vendor/issues/9>`_)
* Contributors: Carlos Agüero

0.2.0 (2024-09-30)
------------------
* Bump version to 9.0.0 (`#5 <https://github.com/gazebo-release/gz_sim_vendor/issues/5>`_)
* Apply prerelease suffix (`#4 <https://github.com/gazebo-release/gz_sim_vendor/issues/4>`_)
  * Apply prerelease suffix
  * Drop BUILD_DOCS
  ---------
* Upgrade to Ionic
* Contributors: Addisu Z. Taddese, Ian Chen

0.1.2 (2024-08-08)
------------------
* Update vendored package version to 8.6.0
* Contributors: Addisu Z. Taddese

0.1.1 (2024-07-15)
------------------
* Update vendored package version to 8.5.0
* Contributors: Addisu Z. Taddese

0.1.0 (2024-04-23)
------------------
* Use an alias target for root library
* Contributors: Addisu Z. Taddese

0.0.2 (2024-04-12)
------------------
* Remove python3-distutils dependency
  This dependency is only needed in the vendored package for CMake
  versions less than 3.12. It is also failing to install on Noble
  currently preventing the whole vendor package from building.
* Update vendored version, add support for the `<pkg>::<pkg>` and `<pkg>::all` targets, fix sourcing of dsv files
* Require calling find_package on the underlying package
* Fix linter (`#1 <https://github.com/gazebo-release/gz_sim_vendor/issues/1>`_)
* Initial import
* Contributors: Addisu Z. Taddese
