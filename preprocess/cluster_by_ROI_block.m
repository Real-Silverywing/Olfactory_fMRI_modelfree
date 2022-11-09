clc
clear
wkdir = 'E:\OneDrive Local\OneDrive - Johns Hopkins\Desktop\Lab\fMRI_data\Model Free Use';
ROIdir = fullfile(wkdir,'My_ROI');
roiname = {'OB', 'OFC', 'olf'};
root = 'E:\OneDrive Local\OneDrive - Johns Hopkins\Desktop\Lab\fMRI_data\Model Free Use';
cd 'E:\OneDrive Local\OneDrive - Johns Hopkins\Desktop\Lab\fMRI_data\Model Free Use'

%% select subject
n=2;



estimate_path = './1st_Block/';
save_path = './cluster_block/';

estimate = {dir([estimate_path,'*7T*']).name};
savedir = fullfile(root, save_path, estimate{n});
funcdir = fullfile(root, estimate{n});
funcfile_name = spm_select('FPlist',funcdir,'^filter.*.nii');
funcfile = load_untouch_nii(funcfile_name);
func = funcfile.img;
ss = size(func);%width,length,time
func_flat = reshape(func,[],ss(4))';
%% select subject and get timecourse
abs_T_thres = 0.1;
sign = 1;
thres = abs_T_thres * sign;

k = 5;

time_courses = cell(1,length(roiname));
cluster_maps = cell(1,length(roiname));
clustered_time_courses = cell(k,length(roiname));
for r = 1:length(roiname) %roi

    t = 1:90;
    mtfiledir = fullfile(root, estimate_path,estimate{n},'mask');
    mtfile_name = spm_select('FPlist',mtfiledir,['ROI_tmap01_',roiname{r},'.nii']);
    mtfile = load_untouch_nii(mtfile_name);
    mtmap3d = mtfile.img;
    mtmap = reshape(mtmap3d,1,[]);
    
    
    thres = abs_T_thres * sign;
    if sign == -1
        activated_voxel = find(mtmap<thres);
        data = double(func_flat(7:96,activated_voxel)');
        time_course = 2*(data - min(data,[],2))./(max(data,[],2)-min(data,[],2)) - 1;

    else
        activated_voxel = find(mtmap>thres);
        data = double(func_flat(7:96,activated_voxel)');
        time_course = 2*(data - min(data,[],2))./(max(data,[],2)-min(data,[],2)) - 1;       
    end
 
    time_courses{r} = time_course;
    cluster_map = zeros(size(mtmap));
    
    if size(time_course,1) >1 && size(time_course,1)>=k
        [idx,C] = kmeans(time_course,k,'Distance','correlation');
        
        cluster_map(activated_voxel) = idx;
        cluster_maps{r} = reshape(cluster_map,size(mtmap3d));
        save_cluster_map(estimate{n},cluster_maps{r},savedir,sign,k,roiname{r})

        
        
        
        clustered_time_course = cell(1,k);
        for i = 1:k
%             clustered_time_course{i} = time_course(idx == i,:);
            clustered_time_courses{i,r} = time_course(idx == i,:);
        end
        
        
        figure
%         title(roiname{r})
        for i = 1:k
            curve = mean(clustered_time_courses{i,r},1);
%             curve = transpose(clustered_time_courses{i,r});
            subplot(k,1,i)

            plot_paradigm_block()
            if sign > 0
                plot(curve,'r')
            else
                plot(curve,'b')
            end
                
            
            title(num2str(size(clustered_time_courses{i,r},1)))
            if i==1
                title([roiname{r},'-',num2str(size(clustered_time_courses{i,r},1))])
            end
            


        end    
        
        
        
    elseif size(time_course,1) > 1 && size(time_course,1)<k
        disp('Activated voxel number smaller than number of cluster')
    else
        disp('No more than one activated voxel')
    end

   
        
    
end
%%
% roi_index = 3;
% figure
% for i = 1:k
%     curve = mean(clustered_time_courses{i,roi_index});
%     subplot(k,1,i)
%     plot_paradigm()
%     plot(curve)
%     
%     
% end
%%
function [] = save_cluster_map(name,cluster_map,path,sign,k,roi)
p = 'E:\OneDrive Local\OneDrive - Johns Hopkins\Desktop\Lab\fMRI_data\Model Free Use\cluster\';
label_name = spm_select('FPlist',p,[name,'_label.nii']);
file = load_untouch_nii(label_name);
file.img = cluster_map;
if sign > 0
    save_fakeuntouch_nii(file,[path,'\',roi,'_posi','_cluster_map',num2str(k),'.nii'])
else
    save_fakeuntouch_nii(file,[path,'\',roi,'_neg','_cluster_map',num2str(k),'.nii'])
end
% niftiwrite(cluster_map,[path,'\cluster_map',num2str(k),'.nii']);
end


% function [] = plot_paradigm()
% %PLOT_PARADIAM Summary of this function goes here
% %   Detailed explanation goes here
% % figure()
% set(gcf,'position',[500,400,1200,400])
% rectangle('Position',[31-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)
% 
% rectangle('Position',[121-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)
% rectangle('Position',[211-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)  %'EdgeColor','blue',
% 
% ylim([-1 1])
% yticks([-1,0,1])
% %yticklabels({'-1','0','1','2'}) %posi
% yticklabels({'-1','0','1'})  %neg
% 
% 
% hold on;
% line([1,276],[0,0],'LineWidth',1.5,'Color','black')
% line([7,36],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
% line([97,126],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
% line([187,216],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
% end

function [] = plot_paradigm_block()
%PLOT_PARADIAM Summary of this function goes here
%   Detailed explanation goes here
% figure()
set(gcf,'position',[500,400,1200,400])
rectangle('Position',[31-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)

% rectangle('Position',[121-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)
% rectangle('Position',[211-24, 0, 29,0.8],'EdgeColor','black','LineWidth',1.5)  %'EdgeColor','blue',

ylim([-1 1])
yticks([-1,0,1])
%yticklabels({'-1','0','1','2'}) %posi
yticklabels({'-1','0','1'})  %neg


hold on;
line([1,276],[0,0],'LineWidth',1.5,'Color','black')
line([7,36],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
% line([97,126],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
% line([187,216],[0,0],'LineWidth',2,'Color','white','LineStyle',':')
xlim([7 96])
end