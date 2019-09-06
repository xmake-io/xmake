export module mod;

class thread {
public:
    thread(...) {}
    void join() {}
};

class atomic_int {
public:
    atomic_int(...) {}
    int operator++() { return 0; }
};

/* gcc would ICE with template */

template <typename T>
class msg_queue {
public:
    void put(...) {}
    T take() { return {}; }
};

export template <int N, int M, int Loops = 1000000>
void test_prod_cons() {
    thread producers[N];
    thread consumers[M];

    struct msg_t {
        int pid_;
        int dat_;
    };
    msg_queue<msg_t> messages;

    int cid = 0;
    for (auto& t : consumers) {
        t = thread{[&, cid] {
            while (1) {
                msg_t msg = messages.take();
                if (msg.pid_ < 0) break;
            }
        }};
        ++cid;
    }

    int pid = 0;
    for (auto& t : producers) {
        t = thread{[&, pid] {
            for (int i = 0; i < Loops; ++i) {
                messages.put(pid, i); // emplace_back
            }
        }};
        ++pid;
    }
    for (auto& t : producers) t.join();
    // quit
    messages.put(-1, -1);
    for (auto& t : consumers) t.join();
}

export template <int N>
struct foo {};

export inline void test_performance(foo<1>, foo<1>) {
    test_prod_cons<1, 1>();
}

export template <int N>
void test_performance(foo<N>, foo<1>) {
    test_performance(foo<N - 1>{}, foo<1>{});
    test_prod_cons<N, 1>();
};

export template <int N, int M>
void test_performance(foo<N>, foo<M>) {
    test_performance(foo<N>{}, foo<M - 1>{});
    test_prod_cons<N, M>();
};
