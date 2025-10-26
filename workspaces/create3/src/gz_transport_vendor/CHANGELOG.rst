^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package gz_transport_vendor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

0.2.1 (2025-02-19)
------------------
* Bump version to 14.0.1 (`#9 <https://github.com/gazebo-release/gz_transport_vendor/issues/9>`_)
* Contributors: Carlos Agüero

0.2.0 (2024-09-30)
------------------
* Bump version to 14.0.0 (`#7 <https://github.com/gazebo-release/gz_transport_vendor/issues/7>`_)
* Apply prerelease suffix (`#6 <https://github.com/gazebo-release/gz_transport_vendor/issues/6>`_)
  * Apply prerelease suffix
  * Drop BUILD_DOCS
  ---------
* Upgrade to Ionic
* Contributors: Addisu Z. Taddese

0.1.2 (2024-07-15)
------------------
* Update vendored package version to 13.4.0
* Contributors: Addisu Z. Taddese

0.1.1 (2024-06-06)
------------------
* Update underlying version to 13.3.0
* Contributors: Addisu Z. Taddese

0.1.0 (2024-04-23)
------------------
* Use an alias target for root library
* Contributors: Addisu Z. Taddese

0.0.3 (2024-04-12)
------------------
* Remove python3-distutils dependency (`#2 <https://github.com/gazebo-release/gz_transport_vendor/issues/2>`_)
  This dependency is only needed in the vendored package for CMake
  versions less than 3.12. It is also failing to install on Noble
  currently preventing the whole vendor package from building.
* Contributors: Addisu Z. Taddese

0.0.2 (2024-04-09)
------------------
* Add support for the `<pkg>::<pkg>` and `<pkg>::all` targets, fix sourcing of dsv files
* Update vendored version
* Require calling find_package on the underlying package
* Fix linter (`#1 <https://github.com/gazebo-release/gz_transport_vendor/issues/1>`_)
* Initial import
* Contributors: Addisu Z. Taddese
