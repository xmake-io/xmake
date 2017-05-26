function main ()
    os.exec("xmake create -P $(tmpdir)/test")
    os.exec("xmake -P $(tmpdir)/test")
    os.exec("xmake create -l c++ -P $(tmpdir)/test_cpp")
    os.exec("xmake -P $(tmpdir)/test_cpp")
    os.exec("xmake create -l c++ -t 3 -P $(tmpdir)/test_cpp2")
    os.exec("xmake -P $(tmpdir)/test_cpp2")
end
