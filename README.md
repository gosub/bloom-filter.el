# bloom-filter.el

An implementation of Bloom filters in elisp.

A Bloom filter is a space efficient, probabilistic data structure that is used to test if an element is a member of a set. False positive are possible, false negatives are not.

Version 0.1.0
Tested with emacs 24.

## Installation

Copy bloom-filter.el in a directory in *load-path*

## Functions

* make-bloom-filter
* bloom-filter-add
* bloom-filter-query
* list-to-bloom-filter
* bloom-filters-union
* bloom-filters-intersection
* bloom-filter-p
* bloom-filter-size
* bloom-filter-hash-funs-num
* bloom-filter-vector

## Usage example

```cl
(require 'bloom-filter)

(setq bf (make-bloom-filter 512 4))

(bloom-filter-add "test" bf)
(bloom-filter-query "test" bf) ;; ==> t
(bloom-filter-query "toast" bf) ;; ==> nil

(setq bf1 (list-to-bloom-filter '(rose lily daisy) 512 4))
(bloom-filter-query 'rose bf1) ;; ==> t
(bloom-filter-query 'violet bf1) ;; ==> nil

(setq bf2 (list-to-bloom-filter '(daisy peach mario luigi) 512 4))
(bloom-filter-query 'rose (bloom-filters-union bf1 bf2)) ;; ==> t
(bloom-filter-query 'daisy (bloom-filters-union bf1 bf2)) ;; ==> t
(bloom-filter-query 'mario (bloom-filters-union bf1 bf2)) ;; ==> t
(bloom-filter-query 'violet (bloom-filters-union bf1 bf2)) ;; ==> nil

(bloom-filter-query 'daisy (bloom-filters-intersection bf1 bf2)) ;; ==> t
(bloom-filter-query 'mario (bloom-filters-intersection bf1 bf2)) ;; ==> nil
(bloom-filter-query 'rose (bloom-filters-intersection bf1 bf2)) ;; ==> nil
```

## Addition informations on Bloom filters

[Wikipedia](http://en.wikipedia.org/wiki/Bloom_filter)

## TODO

* Find a better internal representation (now it's a tagged vector)
* Remove dependency on 'cl
* Move tests to a separate file
* Better test coverage
* Test compatibility with other versions of emacs
* More speed!

## Author

* Giampaolo Guiducci <giampaolo.guiducci@gmail.com>

## License

Copyright (C) 2013-2020 Giampaolo Guiducci

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
