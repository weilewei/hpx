// high_precision_time.hpp

// Boost Logging library
//
// Author: John Torjo, www.torjo.com
//
// Copyright (C) 2007 John Torjo (see www.torjo.com for email)
//
//  SPDX-License-Identifier: BSL-1.0
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org for updates, documentation, and revision history.
// See http://www.torjo.com/log2/ for more details

#ifndef JT28092007_high_precision_time_HPP_DEFINED
#define JT28092007_high_precision_time_HPP_DEFINED

#include <hpx/config.hpp>
#include <hpx/format.hpp>
#include <hpx/logging/manipulator.hpp>

#include <chrono>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <string>

#if !(defined(__linux) || defined(linux) || defined(__linux__) ||              \
    defined(__FreeBSD__) || defined(__APPLE__) || defined(HPX_MSVC))
#include <boost/smart_ptr/detail/spinlock.hpp>
#include <mutex>
#endif

namespace hpx { namespace util { namespace logging { namespace formatter {

    /**
@brief Prefixes the message with a high-precision time (.
You pass the format string at construction.

@code
#include <hpx/logging/format/formatter/high_precision_time.hpp>
@endcode

Internally, it uses hpx::util::date_time::microsec_time_clock.
So, our precision matches this class.

The format can contain escape sequences:
$dd - day, 2 digits
$MM - month, 2 digits
$yy - year, 2 digits
$yyyy - year, 4 digits
$hh - hour, 2 digits
$mm - minute, 2 digits
$ss - second, 2 digits
$mili - milliseconds
$micro - microseconds (if the high precision clock allows; otherwise, it pads zeros)
$nano - nanoseconds (if the high precision clock allows; otherwise, it pads zeros)


Example:

@code
high_precision_time("$mm:$ss:$micro");
@endcode

@param convert [optional] In case there needs to be a conversion between
std::(w)string and the string that holds your logged message. See convert_format.
*/
    struct high_precision_time : manipulator
    {
        /**
        constructs a high_precision_time object
    */
        explicit high_precision_time(std::string const& format)
        {
            set_format(format);
        }

        void set_format(const std::string& format)
        {
            m_format = format;
            replace_format("$dd", "{1:02d}");
            replace_format("$MM", "{2:02d}");
            replace_format("$yyyy", "{3:04d}");
            replace_format("$yy", "{4:02d}");
            replace_format("$hh", "{5:02d}");
            replace_format("$mm", "{6:02d}");
            replace_format("$ss", "{7:02d}");
            replace_format("$mili", "{8:03d}");
            replace_format("$micro", "{9:06d}");
            replace_format("$nano", "{10:09d}");
        }

        void write_high_precision_time(message& msg,
            std::chrono::time_point<std::chrono::system_clock> val) const
        {
            std::time_t tt = std::chrono::system_clock::to_time_t(val);

#if defined(__linux) || defined(linux) || defined(__linux__) ||                \
    defined(__FreeBSD__) || defined(__APPLE__)
            std::tm local_tm;
            localtime_r(&tt, &local_tm);
#elif defined(HPX_MSVC)
            std::tm local_tm;
            localtime_s(&local_tm, &tt);
#else
            // fall back to non-thread-safe version on other platforms
            std::tm local_tm;
            {
                static boost::detail::spinlock mutex =
                    BOOST_DETAIL_SPINLOCK_INIT;
                std::unique_lock<boost::detail::spinlock> ul(mutex);
                local_tm = *std::localtime(&tt);
            }
#endif

            std::chrono::nanoseconds nanosecs =
                std::chrono::duration_cast<std::chrono::nanoseconds>(
                    val.time_since_epoch());
            std::chrono::microseconds microsecs =
                std::chrono::duration_cast<std::chrono::microseconds>(
                    val.time_since_epoch());
            std::chrono::milliseconds millisecs =
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    val.time_since_epoch());

            std::string time_str = hpx::util::format(m_format, local_tm.tm_mday,
                local_tm.tm_mon + 1, local_tm.tm_year + 1900,
                local_tm.tm_year % 100, local_tm.tm_hour, local_tm.tm_min,
                local_tm.tm_sec, millisecs.count() % 1000,
                microsecs.count() % 1000, nanosecs.count() % 1000);
            msg.prepend_string(time_str);
        }

        void operator()(message& msg) override
        {
            write_high_precision_time(msg, std::chrono::system_clock::now());
        }

        /** @brief configure through script

        the string = the time format
    */
        void configure(std::string const& str) override
        {
            set_format(str);
        }

    private:
        bool replace_format(char const* from, char const* to)
        {
            size_t start_pos = m_format.find(from);
            if (start_pos == std::string::npos)
                return false;
            m_format.replace(start_pos, std::strlen(from), to);
            return true;
        }

        std::string m_format;
    };

}}}}    // namespace hpx::util::logging::formatter

#endif
