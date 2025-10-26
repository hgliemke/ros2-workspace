^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package gz_utils_vendor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

0.2.2 (2025-02-19)
------------------
* Bump version to 3.1.1 (`#10 <https://github.com/gazebo-release/gz_utils_vendor/issues/10>`_)
* Contributors: Carlos Agüero

0.2.1 (2024-12-02)
------------------
* Bump version to 3.1.0 (`#8 <https://github.com/gazebo-release/gz_utils_vendor/issues/8>`_)
* Contributors: Michael Carroll

0.2.0 (2024-09-30)
------------------
* Bump version to 3.0.0 (`#7 <https://github.com/gazebo-release/gz_utils_vendor/issues/7>`_)
* Add in a dependency on spdlog_vendor. (`#6 <https://github.com/gazebo-release/gz_utils_vendor/issues/6>`_)
  * Add in a dependency on spdlog_vendor.
  That way when building on e.g. Windows, the paths to
  spdlog will be setup properly before trying to build this
  vendor package.
  * Also remove the spdlog dependency.
  That's because we will just depend on the vendor package to
  provide that dependency for us as necessary.
  ---------
* Remove the BUILD_DOCS cmake argument. (`#5 <https://github.com/gazebo-release/gz_utils_vendor/issues/5>`_)
  It is apparently deprecated in newer Gazebo.
* Apply prerelease suffix (`#4 <https://github.com/gazebo-release/gz_utils_vendor/issues/4>`_)
* Upgrade to Ionic
* Contributors: Addisu Z. Taddese, Chris Lalancette

0.1.0 (2024-04-23)
------------------
* Use an alias target for the root library (`#3 <https://github.com/gazebo-release/gz_utils_vendor/issues/3>`_)
  Without this patch, doing `find_package(gz-utils)` (or any vendor
  package) multiple times in a single CMakeLists file fails with an
  error indicating that cmake cannot create the imported target
  because another target with the same name already exists.
* Contributors: Addisu Z. Taddese

0.0.3 (2024-04-10)
------------------
* Add support for the `<pkg>::<pkg>` and `<pkg>::all` targets, fix sourcing of dsv files
* Contributors: Addisu Z. Taddese

0.0.2 (2024-03-28)
------------------
* Require calling find_package on the underlying package (`#2 <https://github.com/gazebo-release/gz_utils_vendor/issues/2>`_)
* Fix linter (`#1 <https://github.com/gazebo-release/gz_utils_vendor/issues/1>`_)
* Initial import
* Contributors: Addisu Z. Taddese
