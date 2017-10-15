touch ~/.bash_aliases
echo "source /tools/config.sh" >> ~/.bash_aliases
source ~/.bash_aliases
mkdir ~/anaconda3

read -p "Please enter the name of your Anaconda Python 3.5 Environment: " condaname

mkdir ~/anaconda3/"$condaname"

conda create --prefix=~/anaconda3/"$condaname" python=3.5 -y -q
echo "alias activate=\"source activate ~/anaconda3/$condaname\"" >> ~/.bash_aliases
source ~/.bash_aliases
#reset
echo "You might want to source ~/.bash_aliases this one time"
