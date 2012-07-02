// Jubatus: Online machine learning framework for distributed environment
// Copyright (C) 2011 Preferred Infrastructure and Nippon Telegraph and Telephone Corporation.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#include "exception.hpp"
#include "lock_service.hpp"
#include "zk.hpp"
#include "cached_zk.hpp"

namespace jubatus{ namespace common{

lock_service* create_lock_service(const std::string& name,
                                  const std::string& hosts, const int timeout, const std::string& log){

  if(name == "zk"){
    return reinterpret_cast<lock_service*>(new zk(hosts, timeout, log));
  }
  else if(name == "cached_zk"){
    return reinterpret_cast<lock_service*>(new cached_zk(hosts, timeout, log));
  }
  throw JUBATUS_EXCEPTION(jubatus::exception::runtime_error(std::string("unknown lock_service: ") + name));
}

lock_service_mutex::lock_service_mutex(lock_service& ls, const std::string& path):
  path_(path){
  if(ls.type() == "zk" or ls.type() == "cached_zk"){
    impl_ = reinterpret_cast<try_lockable*>(new zkmutex(ls, path));
  }else{
    { LOG(ERROR) << "unknown lock_service: " << ls.type(); }
    throw JUBATUS_EXCEPTION(jubatus::exception::runtime_error(std::string("unknown lock_service: ") + ls.type()));
  }
};

bool lock_service_mutex::lock(){
  return impl_->lock();
}
bool lock_service_mutex::try_lock(){
  return impl_->try_lock();
}
bool lock_service_mutex::unlock(){
  return impl_->unlock();
}

}}
