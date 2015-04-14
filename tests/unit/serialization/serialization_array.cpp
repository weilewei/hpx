//  Copyright (c) 2014 Thomas Heller
//
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

#include <numeric>

#include <hpx/runtime/serialization/serialize.hpp>
#include <hpx/runtime/serialization/array.hpp>
#include <hpx/runtime/serialization/vector.hpp>

#include <hpx/runtime/serialization/input_archive.hpp>
#include <hpx/runtime/serialization/output_archive.hpp>

#include <hpx/util/lightweight_test.hpp>

template <typename T>
struct A
{
    A() {}

    A(T t) : t_(t) {}
    T t_;

    A & operator=(T t) { t_ = t; return *this; }

    template <typename Archive>
    void serialize(Archive & ar, unsigned)
    {
        ar & t_;
    }
};

template <typename T>
void test(T min, T max)
{
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        std::vector<T> os;
        for(T c = min; c < max; ++c)
        {
            os.push_back(c);
        }
        oarchive << hpx::serialization::make_array(&os[0], os.size());

        hpx::serialization::input_archive iarchive(buffer);
        std::vector<T> is; is.resize(os.size());
        iarchive >> hpx::serialization::make_array(&is[0], is.size());
        HPX_TEST_EQ(os.size(), is.size());
        for(std::size_t i = 0; i < os.size(); ++i)
        {
            HPX_TEST_EQ(os[i], is[i]);
        }
    }
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        std::vector<A<T> > os;
        for(T c = min; c < max; ++c)
        {
            os.push_back(c);
        }
        oarchive << hpx::serialization::make_array(&os[0], os.size());

        hpx::serialization::input_archive iarchive(buffer);
        std::vector<A<T> > is; is.resize(os.size());
        iarchive >> hpx::serialization::make_array(&is[0], is.size());
        HPX_TEST_EQ(os.size(), is.size());
        for(std::size_t i = 0; i < os.size(); ++i)
        {
            HPX_TEST_EQ(os[i].t_, is[i].t_);
        }
    }
}

template <typename T>
void test_fp(T min, T max)
{
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        std::vector<T> os;
        for(T c = min; c < max; c += static_cast<T>(0.5))
        {
            os.push_back(c);
        }
        oarchive << hpx::serialization::make_array(&os[0], os.size());

        hpx::serialization::input_archive iarchive(buffer);
        std::vector<T> is; is.resize(os.size());
        iarchive >> hpx::serialization::make_array(&is[0], is.size());
        HPX_TEST_EQ(os.size(), is.size());
        for(std::size_t i = 0; i < os.size(); ++i)
        {
            HPX_TEST_EQ(os[i], is[i]);
        }
    }
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        std::vector<A<T> > os;
        for(T c = min; c < max; c += static_cast<T>(0.5))
        {
            os.push_back(c);
        }
        oarchive << hpx::serialization::make_array(&os[0], os.size());

        hpx::serialization::input_archive iarchive(buffer);
        std::vector<A<T> > is; is.resize(os.size());
        iarchive >> hpx::serialization::make_array(&is[0], is.size());
        HPX_TEST_EQ(os.size(), is.size());
        for(std::size_t i = 0; i < os.size(); ++i)
        {
            HPX_TEST_EQ(os[i].t_, is[i].t_);
        }
    }
}

template <class T, std::size_t N>
void test_boost_array(T first)
{
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        boost::array<T, N> oarray;
        std::iota(oarray.begin(), oarray.end(), first);
        oarchive << oarray;

        hpx::serialization::input_archive iarchive(buffer);
        boost::array<T, N> iarray;
        iarchive >> iarray;
        for(std::size_t i = 0; i < oarray.size(); ++i)
        {
            HPX_TEST_EQ(oarray[i], iarray[i]);
        }
    }
    {
        std::vector<char> buffer;
        hpx::serialization::output_archive oarchive(buffer);
        boost::array<A<T>, N> oarray;
        std::iota(oarray.begin(), oarray.end(), first);
        oarchive << oarray;

        hpx::serialization::input_archive iarchive(buffer);
        boost::array<A<T> , N> iarray;
        iarchive >> iarray;
        for(std::size_t i = 0; i < oarray.size(); ++i)
        {
            HPX_TEST_EQ(oarray[i].t_, iarray[i].t_);
        }
    }
}

int main()
{
    test<char>(std::numeric_limits<char>::min(), std::numeric_limits<char>::max());
    test<int>(std::numeric_limits<int>::min(), std::numeric_limits<int>::min() + 100);
    test<int>(std::numeric_limits<int>::max() - 100, std::numeric_limits<int>::max());
    test<int>(-100, 100);
    test<unsigned>(std::numeric_limits<unsigned>::min(), std::numeric_limits<unsigned>::min() + 100);
    test<unsigned>(std::numeric_limits<unsigned>::max() - 100, std::numeric_limits<unsigned>::max());
    test<long>(std::numeric_limits<long>::min(), std::numeric_limits<long>::min() + 100);
    test<long>(std::numeric_limits<long>::max() - 100, std::numeric_limits<long>::max());
    test<long>(-100, 100);
    test<unsigned long>(std::numeric_limits<unsigned long>::min(), std::numeric_limits<unsigned long>::min() + 100);
    test<unsigned long>(std::numeric_limits<unsigned long>::max() - 100, std::numeric_limits<unsigned long>::max());
    test_fp<float>(std::numeric_limits<float>::min(), std::numeric_limits<float>::min() + 100);
    test_fp<float>(-100, 100);
    test<double>(std::numeric_limits<double>::min(), std::numeric_limits<double>::min() + 100);
    test<double>(-100, 100);

    test_boost_array<char, 100U>('\0');
    test_boost_array<double, 40U>(std::numeric_limits<double>::min());
    test_boost_array<float, 100U>(0.f);
    return hpx::util::report_errors();
}
